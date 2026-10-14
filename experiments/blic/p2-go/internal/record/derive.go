package record

import (
	"fmt"
	"sort"
	"strings"
)

// StateName is the state word with the pointer removed. read.sh reports `done(PR#11)` as one
// token because the status line writes it as one token.
func StateName(s string) string {
	if i := strings.IndexAny(s, "("); i >= 0 {
		return strings.TrimSpace(s[:i])
	}
	return strings.TrimSpace(s)
}

// StatePointer is the parenthesised part: `done(PR#11)` is pointer `PR#11`.
func StatePointer(s string) string {
	i := strings.Index(s, "(")
	j := strings.LastIndex(s, ")")
	if i < 0 || j <= i {
		return ""
	}
	return strings.TrimSpace(s[i+1 : j])
}

// StateName on the brief itself.
func (b Brief) StateName() string { return StateName(b.State) }

// Open is the brief states that still want attention. read.sh reports `planned` for a brief
// with no ledger and `no-line` for a ledger whose status line is missing; both are open, and
// both are states tools/list-briefs.sh and docs/blc/briefs/README.md disagree about.
func (b Brief) Open() bool {
	switch b.StateName() {
	case "done", "abandoned", "superseded":
		return false
	}
	return true
}

// InFlight is the first phase that is not finished, which is the phase a person is actually
// on. A brief whose phases are all done but whose status line is not is in flight at the
// brief level, and that is reported as a nil phase with a non-empty reason.
func (b Brief) InFlight() *Phase {
	for i := range b.Phases {
		switch StateName(b.Phases[i].State) {
		case "done", "skipped", "abandoned":
			continue
		}
		return &b.Phases[i]
	}
	return nil
}

// Progress counts finished phases against all phases.
func (b Brief) Progress() (done, total int) {
	for _, p := range b.Phases {
		total++
		switch StateName(p.State) {
		case "done", "skipped", "abandoned":
			done++
		}
	}
	return done, total
}

// NextAction is the brief's open question #3: whether a next action is derivable from the
// record at all. It is derivable only in the shapes below. Everything else returns a sentence
// that says what is known and does not invent a verb, because a console that guesses the next
// action is worse than one that reports the state.
//
// defects are the gate's judgments against this brief, which carry the one next action the
// ledger cannot imply on its own: a done brief with no Closed date wants blc-close-brief.
func (b Brief) NextAction(defects []Defect) (action, why string) {
	for _, d := range defects {
		if strings.Contains(d.Message, "no **Closed:** date") {
			return "blc-close-brief", d.Clause + ": status line says done and the ledger records no Closed date"
		}
	}
	if !b.HasLedger {
		return "blc-start-brief", "filed serial with no ledger: nothing has planned the phases"
	}
	switch b.StateName() {
	case "no-line":
		return "repair the status line", "the ledger carries no status line, so every cheap scan of this brief reports nothing"
	case "done", "abandoned", "superseded":
		return "none", "state is " + b.StateName()
	}
	p := b.InFlight()
	if p == nil {
		return "blc-close-brief", "every phase is finished and the brief status line still says " + b.StateName()
	}
	label := p.Label
	if label == "" {
		label = "(the ledger table carries no label for this phase)"
	}
	switch StateName(p.State) {
	case "in-progress":
		if p.Pointer != "" {
			return "blc-review-pr then blc-commit-push-pr", fmt.Sprintf("phase %s is in progress at %s — %s", p.ID, p.Pointer, label)
		}
		return "finish phase " + p.ID + ", then blc-commit-push-pr", fmt.Sprintf("phase %s is in progress — %s", p.ID, label)
	case "planned", "":
		return "blc-next-brief-phase", fmt.Sprintf("phase %s is planned and not started — %s", p.ID, label)
	case "blocked":
		return "unblock phase " + p.ID, fmt.Sprintf("phase %s is blocked — %s", p.ID, label)
	default:
		return "none derivable", fmt.Sprintf("phase %s is %q, which is not a state this console knows", p.ID, StateName(p.State))
	}
}

// DefectsFor matches the gate's subject to a brief. validate-briefs.sh names its subject by
// slug, so the match is on slug and on the bare serial for the lines that use it.
func DefectsFor(b Brief, all []Defect) []Defect {
	var out []Defect
	for _, d := range all {
		s := d.Subject
		if s == b.Slug || s == b.Serial || strings.HasPrefix(s, b.Serial+"-") || strings.HasPrefix(s, "#"+b.Serial) {
			out = append(out, d)
		}
	}
	return out
}

// Attention orders briefs the way a person starting the day wants them: mine before theirs,
// in flight before planned, defective before clean, then by serial descending so the newest
// filed work is near the top.
func Attention(briefs []Brief, defects []Defect) []Brief {
	out := append([]Brief(nil), briefs...)
	score := func(b Brief) int {
		n := 0
		if b.Mine {
			n -= 8
		}
		if b.Open() {
			n -= 4
		}
		if len(DefectsFor(b, defects)) > 0 {
			n -= 2
		}
		if b.StateName() == "in-progress" {
			n -= 1
		}
		return n
	}
	sort.SliceStable(out, func(i, j int) bool {
		si, sj := score(out[i]), score(out[j])
		if si != sj {
			return si < sj
		}
		return out[i].Serial > out[j].Serial
	})
	return out
}
