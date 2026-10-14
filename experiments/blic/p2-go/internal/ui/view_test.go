package ui

import (
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/termenv"

	"blic/p2go/internal/record"
)

func testModel(t *testing.T) Model {
	t.Helper()
	lipgloss.SetColorProfile(termenv.Ascii)
	m := New(Options{})
	m.width, m.height = 120, 36
	m.now = time.Now()
	snap := &record.Snapshot{
		Me:     record.Identity{Email: "me@example.test"},
		Head:   "abc1234",
		Branch: "blic/p2-go",
		Repo:   "/tmp/fixture",
		Briefs: []record.Brief{
			{Serial: "0039", Slug: "0039-x", Title: "In flight and mine", State: "in-progress", Mine: true, HasLedger: true,
				Phases: []record.Phase{{ID: "a", State: "in-progress", Pointer: "br", Label: "the phase"}}},
			{Serial: "0028", Slug: "0028-y", Title: "Done with no closed date", State: "done", Mine: true, HasLedger: true},
		},
		Defects: []record.Defect{{Clause: "BRIEFS-11", Kind: "judgment", Subject: "0028-y",
			Message: "status line says done, and ledger.md records no **Closed:** date"}},
		Events: []record.Event{{SHA: "aaaa", Who: "me@example.test", Mine: true, Kind: "phase", Serial: "0039", Phase: "a", Subject: "[#0039a] a real one"}},
	}
	model, _ := m.Update(snapshotMsg{snap: snap, dur: 3 * time.Second})
	return model.(Model)
}

// TestSyntheticEventsAreLabelledInText is the test the fixture's README implies: a synthetic
// event must be distinguishable with the colours stripped, because a capture of a session is
// plain text and a colour-only mark does not survive it.
func TestSyntheticEventsAreLabelledInText(t *testing.T) {
	m := testModel(t)
	m.pushEvent(record.Event{SHA: "c0ffee01", Who: "dana@example.test", Synthetic: true,
		Kind: "phase", Serial: "0024", Phase: "b", Subject: "split the renderer"})
	out := m.View()
	if !strings.Contains(out, "SYNTH") {
		t.Error("a synthetic event rendered with no textual mark")
	}
	if !strings.Contains(out, "1 synthetic") {
		t.Error("the feed header does not count synthetic events")
	}
}

// TestHidingSyntheticLeavesOnlyRealEvents covers the key that makes the feed trustworthy.
func TestHidingSyntheticLeavesOnlyRealEvents(t *testing.T) {
	m := testModel(t)
	m.pushEvent(record.Event{SHA: "c0ffee01", Synthetic: true, Kind: "phase", Subject: "invented"})
	next, _ := m.Update(keyMsg("s"))
	out := next.(Model).View()
	if strings.Contains(out, "invented") {
		t.Error("s did not hide the synthetic event")
	}
	if !strings.Contains(out, "a real one") {
		t.Error("s hid the real events too")
	}
}

// TestNewCounterCountsOnlyWhatIDidNotDo is the brief's second question, in one assertion.
func TestNewCounterCountsOnlyWhatIDidNotDo(t *testing.T) {
	m := testModel(t)
	if m.arrived != 0 {
		t.Fatalf("opened claiming %d new events; the first read is not news", m.arrived)
	}
	m.pushEvent(record.Event{SHA: "x1", Mine: true, Kind: "phase", Subject: "mine"})
	if m.arrived != 0 {
		t.Error("counted my own commit as something that changed")
	}
	m.pushEvent(record.Event{SHA: "x2", Mine: false, Synthetic: true, Kind: "phase", Subject: "theirs"})
	if m.arrived != 1 {
		t.Errorf("arrived = %d, want 1", m.arrived)
	}
	cleared, _ := m.Update(keyMsg("a"))
	if cleared.(Model).arrived != 0 {
		t.Error("a did not clear the counter")
	}
}

// TestEventPollMergesWithoutRereadingEverything covers the cheap cadence: a later
// `read.sh events` adds what is new and does not re-count what the snapshot already showed.
func TestEventPollMergesWithoutRereadingEverything(t *testing.T) {
	m := testModel(t)
	before := len(m.feed)
	next, _ := m.Update(eventsMsg{events: []record.Event{
		{SHA: "aaaa", Mine: true, Kind: "phase", Subject: "[#0039a] a real one"}, // already seen
		{SHA: "bbbb", Mine: false, Kind: "close", Serial: "0024", Subject: "docs: close #0024"},
	}})
	m = next.(Model)
	if len(m.feed) != before+1 {
		t.Errorf("feed grew by %d, want 1: the seen commit was counted twice", len(m.feed)-before)
	}
	if m.arrived != 1 {
		t.Errorf("arrived = %d, want 1", m.arrived)
	}
}

func TestFilterKeysChangeTheList(t *testing.T) {
	m := testModel(t)
	if n := len(m.visible()); n != 1 {
		t.Fatalf("default filter shows %d briefs, want 1 (mine and in flight)", n)
	}
	all, _ := m.Update(keyMsg("5"))
	if n := len(all.(Model).visible()); n != 2 {
		t.Errorf("filter 5 shows %d, want 2", n)
	}
	flagged, _ := m.Update(keyMsg("4"))
	v := flagged.(Model).visible()
	if len(v) != 1 || v[0].Serial != "0028" {
		t.Errorf("filter 4 shows %v, want only 0028", v)
	}
}

func TestSearchFiltersAndEscClears(t *testing.T) {
	m := testModel(t)
	step, _ := m.Update(keyMsg("5"))
	step, _ = step.(Model).Update(keyMsg("/"))
	for _, r := range "0028" {
		step, _ = step.(Model).Update(keyMsg(string(r)))
	}
	if n := len(step.(Model).visible()); n != 1 {
		t.Errorf("search for 0028 shows %d briefs, want 1", n)
	}
	cleared, _ := step.(Model).Update(keyMsg("esc"))
	if n := len(cleared.(Model).visible()); n != 2 {
		t.Errorf("esc left %d briefs, want all 2 back", n)
	}
}

// TestDetailShowsTheDerivedNextAction keeps the detail pane honest: the next action and the
// evidence for it are both on screen, because an action with no evidence is a guess.
func TestDetailShowsTheDerivedNextAction(t *testing.T) {
	m := testModel(t)
	flagged, _ := m.Update(keyMsg("4"))
	out := flagged.(Model).View()
	if !strings.Contains(out, "blc-close-brief") {
		t.Error("the detail pane does not name the derived next action")
	}
	if !strings.Contains(out, "BRIEFS-11") {
		t.Error("the detail pane does not cite the judgment the action came from")
	}
}

// TestEveryFrameIsExactlyOneScreen. A console you glance at must not scroll the terminal.
func TestEveryFrameIsExactlyOneScreen(t *testing.T) {
	m := testModel(t)
	for _, key := range []string{"1", "2", "3", "4", "5", "tab", "tab", "j", "k", "G", "g", "enter"} {
		next, _ := m.Update(keyMsg(key))
		m = next.(Model)
		lines := strings.Split(m.View(), "\n")
		if len(lines) > m.height {
			t.Fatalf("after %q the view is %d lines, taller than the %d-row terminal", key, len(lines), m.height)
		}
		for i, l := range lines {
			if w := lipgloss.Width(l); w > m.width {
				t.Fatalf("after %q line %d is %d cells wide, wider than %d", key, i, w, m.width)
			}
		}
	}
}

func TestHelpRendersWithoutASnapshot(t *testing.T) {
	lipgloss.SetColorProfile(termenv.Ascii)
	m := New(Options{})
	shown, _ := m.Update(keyMsg("?"))
	if !strings.Contains(shown.(Model).View(), "peer-events.sh") {
		t.Error("the help screen does not say where synthetic events come from")
	}
}

func TestEmptyModelRendersBeforeTheFirstRead(t *testing.T) {
	lipgloss.SetColorProfile(termenv.Ascii)
	m := New(Options{})
	m.width, m.height = 100, 30
	if !strings.Contains(m.View(), "reading the record") {
		t.Error("the first frame does not say it is reading")
	}
}
