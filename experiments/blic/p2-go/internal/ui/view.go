package ui

import (
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/charmbracelet/lipgloss"

	"blic/p2go/internal/record"
)

// View composes header, two columns and the status bar into exactly one screen. Nothing
// scrolls the terminal: a console you alt-tab into must look the same every time.
func (m Model) View() string {
	if m.help {
		return m.helpView()
	}

	statusH := 2
	if m.err != "" || m.peerErr != "" {
		statusH = 3
	}
	bodyH := m.height - 1 - statusH
	if bodyH < 8 {
		bodyH = 8
	}

	leftW := m.width * 38 / 100
	if leftW < 40 {
		leftW = 40
	}
	if leftW > m.width-34 {
		leftW = m.width - 34
	}
	if leftW < 20 {
		leftW = m.width
	}
	rightW := m.width - leftW

	detailH := bodyH * 58 / 100
	if detailH < 10 {
		detailH = 10
	}
	if detailH > bodyH-6 {
		detailH = bodyH - 6
	}
	feedH := bodyH - detailH

	left := m.briefPane(leftW, bodyH)
	right := lipgloss.JoinVertical(lipgloss.Left,
		m.detailPane(rightW, detailH),
		m.feedPane(rightW, feedH),
	)
	body := lipgloss.JoinHorizontal(lipgloss.Top, left, right)

	return strings.Join([]string{m.header(), body, m.statusBar()}, "\n")
}

func (m Model) header() string {
	branch, head, repo := "—", "—", "—"
	if m.snap != nil {
		branch, head = m.snap.Branch, m.snap.Head
		if i := strings.LastIndex(m.snap.Repo, "/"); i >= 0 {
			repo = m.snap.Repo[i+1:]
		}
	}
	segs := []seg{
		{"BLIC ", styAccentB},
		{"p2 · go+bubbletea ", styDim},
		{"│ " + repo + " ", styBase},
		{"│ " + branch + " @" + head + " ", styDim},
	}
	if m.arrived > 0 {
		segs = append(segs, seg{fmt.Sprintf("│ %d NEW since you opened (a to clear) ", m.arrived), styFlightB})
	}
	return renderRow(segs, m.width)
}

// ── briefs ──────────────────────────────────────────────────────────────────

func (m Model) briefPane(w, h int) string {
	v := m.visible()
	total := 0
	if m.snap != nil {
		total = len(m.snap.Briefs)
	}
	title := fmt.Sprintf("BRIEFS · %s · %d of %d", m.filter, len(v), total)
	if m.searching || m.search != "" {
		title = fmt.Sprintf("BRIEFS · /%s · %d of %d", m.search, len(v), total)
	}

	inner := w - 2
	rows := h - 3 // border, title
	body := make([]string, 0, rows+1)

	if m.snap == nil {
		body = append(body, renderRow([]seg{{" reading the record…", styDim}}, inner))
		return pane(title, m.focus == FocusList, body, w, h)
	}
	if len(v) == 0 {
		body = append(body, renderRow([]seg{{" nothing matches this filter. f cycles, / searches.", styDim}}, inner))
		return pane(title, m.focus == FocusList, body, w, h)
	}

	start, end := scrollWindow(len(v), m.cursor, rows)
	for i := start; i < end; i++ {
		b := v[i]
		sel := i == m.cursor
		defs := record.DefectsFor(b, m.snap.Defects)
		state := b.StateName()
		done, tot := b.Progress()

		marker := "  "
		if sel {
			marker = "▸ "
		}
		mine := " "
		if b.Mine {
			mine = "●"
		}
		flag := "  "
		if len(defs) > 0 {
			flag = fmt.Sprintf("!%d", len(defs))
			if len(defs) > 9 {
				flag = "!+"
			}
		}
		prog := "   "
		if tot > 0 {
			prog = fmt.Sprintf("%d/%d", done, tot)
		}
		segs := []seg{
			{marker, styAccentB},
			{mine + " ", styAccent},
			{b.Serial + " ", styBase},
			{pad(state, 12), stateStyle(state)},
			{pad(prog, 4), styDim},
			{flag + " ", styDefectB},
			{trunc(b.Title, max(8, inner-28)), styBase},
		}
		// The selected row drops the per-field colours for one background. Six foreground
		// colours on a highlighted line is noise; the detail pane already carries the state.
		if sel {
			body = append(body, stySelected.Render(plainRow(segs, inner)))
		} else {
			body = append(body, renderRow(segs, inner))
		}
	}
	if end < len(v) {
		body = append(body, renderRow([]seg{{fmt.Sprintf(" … %d more below", len(v)-end), styDim}}, inner))
	}
	// The default filter is one brief wide in this repository, and a pane that is 90% blank
	// wastes the only screen the console has. The spare rows carry the two things the fixture
	// shows on open that no filter puts in front of you: the gate's standing judgments, and
	// who has claimed work nobody has filed.
	if spare := rows - len(body) - 1; spare >= 5 {
		body = append(body, m.digest(inner, spare)...)
	}
	return pane(title, m.focus == FocusList, body, w, h)
}

// digest fills the brief pane's spare rows with the standing state of the record: the gate's
// judgments grouped by clause, and the declaration window the project rules call invisible.
func (m Model) digest(inner, rows int) []string {
	var out []string
	add := func(segs ...seg) {
		if len(out) < rows {
			out = append(out, renderRow(segs, inner))
		}
	}
	add(seg{strings.Repeat("─", inner), styDim})

	byClause := map[string]int{}
	var order []string
	for _, d := range m.snap.Defects {
		if byClause[d.Clause] == 0 {
			order = append(order, d.Clause)
		}
		byClause[d.Clause]++
	}
	sort.Strings(order)
	if len(m.snap.Defects) == 0 {
		add(seg{" GATE  ", styDone}, seg{"no judgments against 39 briefs", styDone})
	} else {
		add(seg{" GATE  ", styDefectB}, seg{fmt.Sprintf("%d judgments · press 4 to list them", len(m.snap.Defects)), styDefect})
		for _, c := range order {
			add(seg{"   " + pad(c, 11), styDefectB}, seg{fmt.Sprintf("× %d", byClause[c]), styBase})
		}
	}

	if len(m.snap.Declarations) == 0 {
		add(seg{" CLAIMS ", styDim}, seg{"nobody has declared unfiled work", styDim})
	} else {
		add(seg{" CLAIMS ", styAccentB}, seg{fmt.Sprintf("%d contributor(s) hold unfiled work", len(m.snap.Declarations)), styBase})
		for _, d := range m.snap.Declarations {
			add(seg{"   " + pad(trunc(d.Who, 22), 23), styAccent}, seg{strings.Join(d.Claims, ", "), styBase})
		}
	}
	return out
}

// plainRow is the unstyled text of a row, for the selected line where one background colour
// reads better than six foreground ones.
func plainRow(segs []seg, width int) string {
	s := plain(segs)
	r := []rune(s)
	if len(r) > width {
		return string(r[:width])
	}
	return s + strings.Repeat(" ", width-len(r))
}

// ── detail ──────────────────────────────────────────────────────────────────

// detailPane is the answer to "what is mine to do next" for one brief: the derived next
// action first, the evidence under it, then the phase table and the gate's judgments.
func (m Model) detailPane(w, h int) string {
	inner := w - 2
	b := m.selected()
	if b == nil {
		return pane("DETAIL", m.focus == FocusDetail, nil, w, h)
	}
	defs := record.DefectsFor(*b, m.snap.Defects)
	action, why := b.NextAction(defs)

	var lines []string
	add := func(segs ...seg) { lines = append(lines, renderRow(segs, inner)) }

	add(seg{"#" + b.Serial + " ", styAccentB}, seg{trunc(b.Title, inner-8), styTitle})
	owner := b.Owner
	note := ""
	if owner == "" {
		owner, note = b.Author, " (author; no Owner line)"
	}
	who := owner + note
	if b.Mine {
		who += "  ← mine"
	}
	add(seg{" " + trunc(who, inner-1), styAccent})
	add(seg{" " + b.Dir, styDim})
	closed := b.Closed
	if closed == "" {
		closed = "no Closed date"
	}
	add(seg{fmt.Sprintf(" filed %s · touched %s · %s", firstWord(b.Created, 10), ago(b.Touched, m.now), closed), styDim})
	add()

	add(seg{" NEXT  ", styFlightB}, seg{trunc(action, inner-8), styTitle})
	for _, l := range wrap(why, inner-8) {
		add(seg{"       ", styDim}, seg{l, styDim})
	}
	add()

	add(seg{" STATUS ", styDim}, seg{trunc(orDash(b.StatusLine, "the ledger carries no status line"), inner-9), stateStyle(b.StateName())})
	add()

	add(seg{" PHASES", styTitle})
	if len(b.Phases) == 0 {
		reason := "the status line lists no phases"
		if !b.HasLedger {
			reason = "no ledger: this serial is filed and nothing has planned it"
		}
		add(seg{"   " + reason, styDim})
	} else {
		add(seg{"   id  " + pad("state", 13) + pad("pointer", 20) + "label", styDim})
		for _, p := range b.Phases {
			st := record.StateName(p.State)
			ptr := p.Pointer
			if ptr == "" {
				ptr = record.StatePointer(p.State)
			}
			label := p.Label
			lstyle := styBase
			if label == "" {
				label, lstyle = "(no row in the ledger table)", styDim
			}
			add(
				seg{"   " + pad(p.ID, 4), styBase},
				seg{pad(st, 13), stateStyle(st)},
				seg{pad(trunc(orDash(ptr, "—"), 19), 20), styDim},
				seg{trunc(label, max(6, inner-40)), lstyle},
			)
		}
	}
	add()

	if len(defs) == 0 {
		add(seg{" GATE  ", styDim}, seg{"no judgments against this brief", styDone})
	} else {
		add(seg{" GATE  ", styDefectB}, seg{fmt.Sprintf("%d judgment(s) from tools/validate-briefs.sh", len(defs)), styDefect})
		for _, d := range defs {
			add(seg{"   " + pad(d.Clause, 10), styDefectB}, seg{trunc(d.Message, max(10, inner-14)), styBase})
		}
	}

	rows := h - 3
	start := m.detailScroll
	if start > max(0, len(lines)-rows) {
		start = max(0, len(lines)-rows)
	}
	end := min(start+rows, len(lines))
	visible := lines[start:end]
	title := "DETAIL"
	if end < len(lines) || start > 0 {
		title = fmt.Sprintf("DETAIL · lines %d–%d of %d · j/k scrolls", start+1, end, len(lines))
	}
	return pane(title, m.focus == FocusDetail, visible, w, h)
}

// ── feed ────────────────────────────────────────────────────────────────────

// feedPane is "what changed that I did not do". Every synthetic line carries the word
// SYNTHETIC, not only a colour: the capture of this session is plain text, and a reader of
// that capture must still be able to tell the invented events from the real ones.
func (m Model) feedPane(w, h int) string {
	inner := w - 2
	f := m.visibleFeed()
	real, synth := 0, 0
	for _, e := range m.feed {
		if e.Synthetic {
			synth++
		} else {
			real++
		}
	}
	title := fmt.Sprintf("FEED · %d git · %d synthetic · s hides synthetic", real, synth)
	if !m.showSynth {
		title = fmt.Sprintf("FEED · %d git · %d synthetic hidden · s shows them", real, synth)
	}

	rows := h - 3
	body := make([]string, 0, rows+1)
	if len(f) == 0 {
		body = append(body, renderRow([]seg{{" nothing yet", styDim}}, inner))
		return pane(title, m.focus == FocusFeed, body, w, h)
	}
	start, end := scrollWindow(len(f), m.feedCursor, rows)
	for i := start; i < end; i++ {
		e := f[i]
		sel := i == m.feedCursor && m.focus == FocusFeed
		mark := "  "
		if sel {
			mark = "▸ "
		}
		tag := "        "
		tagSty := styDim
		if e.Synthetic {
			tag = "SYNTH ⚠ "
			tagSty = stySynthTag
		} else if e.Mine {
			tag = "mine    "
		}
		ref := e.Serial
		if ref != "" {
			ref = "#" + ref + e.Phase
		}
		subjSty := styBase
		if e.Synthetic {
			subjSty = stySynth
		}
		segs := []seg{
			{mark, styAccentB},
			{clock(e.When) + " ", styDim},
			{tag, tagSty},
			{pad(e.Kind, 12), kindStyle(e.Kind)},
			{pad(ref, 7), styAccent},
			{trunc(e.Subject, max(10, inner-38)), subjSty},
		}
		if sel {
			body = append(body, stySelected.Render(plainRow(segs, inner)))
		} else {
			body = append(body, renderRow(segs, inner))
		}
	}
	return pane(title, m.focus == FocusFeed, body, w, h)
}

func kindStyle(kind string) lipgloss.Style {
	switch kind {
	case "phase":
		return styFlight
	case "close":
		return styDone
	case "filed":
		return styAccent
	case "declaration":
		return styDefect
	case "record":
		return styBase
	default:
		return styDim
	}
}

// ── status bar ──────────────────────────────────────────────────────────────

func (m Model) statusBar() string {
	me, briefs, defects, decls := "—", 0, 0, 0
	if m.snap != nil {
		me = m.snap.Me.Email
		briefs = len(m.snap.Briefs)
		defects = len(m.snap.Defects)
		decls = len(m.snap.Declarations)
	}
	mineOpen := 0
	for _, b := range m.visibleAll() {
		if b.Mine && b.Open() {
			mineOpen++
		}
	}
	read := "reading…"
	if !m.loading && m.snap != nil {
		read = fmt.Sprintf("full read %.1fs %s · events %s",
			m.loadDur.Seconds(),
			ago(m.loadedAt.Format(time.RFC3339), m.now),
			ago(m.eventsAt.Format(time.RFC3339), m.now))
	}
	peer := "peer off"
	if m.peer != nil {
		peer = "peer on"
	}
	if m.peerNote != "" {
		peer = m.peerNote
	}
	l1 := renderRow([]seg{
		{" " + me + " ", styAccent},
		{fmt.Sprintf("│ %d briefs, %d mine and open ", briefs, mineOpen), styBase},
		{fmt.Sprintf("│ %d gate judgments ", defects), map[bool]lipgloss.Style{true: styDefectB, false: styDone}[defects > 0]},
		{fmt.Sprintf("│ %d declarations ", decls), styBase},
		{"│ " + read + " ", styDim},
		{"│ " + peer, stySynth},
	}, m.width)

	l2 := renderRow([]seg{
		{" j/k ", styKey}, {"move  ", styDim},
		{"tab ", styKey}, {"pane  ", styDim},
		{"1-5/f ", styKey}, {"filter  ", styDim},
		{"/ ", styKey}, {"search  ", styDim},
		{"r ", styKey}, {"reread  ", styDim},
		{"s ", styKey}, {"synthetic  ", styDim},
		{"a ", styKey}, {"ack new  ", styDim},
		{"? ", styKey}, {"help  ", styDim},
		{"q ", styKey}, {"quit", styDim},
	}, m.width)

	out := []string{styBar.Render(l1), l2}
	if m.err != "" {
		out = append(out, renderRow([]seg{{" ERROR ", styDefectB}, {trunc(m.err, m.width-8), styDefect}}, m.width))
	} else if m.peerErr != "" {
		out = append(out, renderRow([]seg{{" PEER  ", styDefectB}, {trunc(m.peerErr, m.width-8), styDefect}}, m.width))
	}
	return strings.Join(out, "\n")
}

func (m Model) visibleAll() []record.Brief {
	if m.snap == nil {
		return nil
	}
	return m.snap.Briefs
}

func (m Model) helpView() string {
	rows := [][2]string{
		{"j / k, ↑ / ↓", "move in the focused pane"},
		{"g / G", "first / last"},
		{"ctrl+d / ctrl+u", "page"},
		{"tab / shift+tab", "cycle focus: briefs → detail → feed"},
		{"enter", "focus the detail pane"},
		{"1", "mine, in flight (the default)"},
		{"2", "in flight, anyone's"},
		{"3", "mine, including closed"},
		{"4", "flagged by tools/validate-briefs.sh"},
		{"5", "all 39"},
		{"f", "cycle those five"},
		{"/", "search serial, title, slug, assignee · esc clears"},
		{"r", "reread everything now (events reread every 20s, the rest every 5m)"},
		{"s", "hide or show synthetic peer events"},
		{"a", "acknowledge the NEW counter"},
		{"? / esc", "this screen"},
		{"q / ctrl+c", "quit"},
	}
	var lines []string
	lines = append(lines, styTitle.Render("  BLIC p2 — go + bubble tea"), "")
	for _, r := range rows {
		lines = append(lines, "  "+styKey.Render(pad(r[0], 18))+styBase.Render(r[1]))
	}
	lines = append(lines,
		"",
		styDim.Render("  Data comes from experiments/blic/read.sh. This console never writes the record."),
		styDim.Render("  Events marked SYNTH ⚠ come from peer-events.sh and did not happen."),
		"",
		styDim.Render("  ● marks a brief assigned to you: Owner, or Author when there is no Owner."),
		styDim.Render("  !n is the number of judgments tools/validate-briefs.sh holds against it."),
	)
	return strings.Join(lines, "\n")
}

func orDash(s, alt string) string {
	if strings.TrimSpace(s) == "" {
		return alt
	}
	return s
}

func firstWord(s string, n int) string {
	if s == "" {
		return "—"
	}
	r := []rune(s)
	if len(r) > n {
		return string(r[:n])
	}
	return s
}

// wrap is a word wrap for the one place prose appears: the reason under the next action.
func wrap(s string, width int) []string {
	if width < 10 {
		width = 10
	}
	words := strings.Fields(s)
	var out []string
	cur := ""
	for _, w := range words {
		if cur == "" {
			cur = w
		} else if len([]rune(cur))+1+len([]rune(w)) <= width {
			cur += " " + w
		} else {
			out = append(out, cur)
			cur = w
		}
	}
	if cur != "" {
		out = append(out, cur)
	}
	return out
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
