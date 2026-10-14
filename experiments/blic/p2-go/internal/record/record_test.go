package record

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// repoRootForTest finds the checkout this test is running inside.
func repoRootForTest(t *testing.T) string {
	t.Helper()
	root, err := RepoRoot(".")
	if err != nil {
		t.Skipf("not in a checkout: %v", err)
	}
	return root
}

// TestSnapshotDecodesStrictly is the only guard the typed boundary has. read.sh publishes no
// schema and has no tests of its own, so this test is what notices a field it grows or drops.
func TestSnapshotDecodesStrictly(t *testing.T) {
	root := repoRootForTest(t)
	rd := NewReader(root)
	if _, err := os.Stat(rd.ReadSH); err != nil {
		t.Skipf("read surface absent: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()
	snap, _, err := rd.Snapshot(ctx)
	if err != nil {
		t.Fatalf("snapshot: %v", err)
	}
	if len(snap.Briefs) == 0 {
		t.Fatal("no briefs: the fixture is this repository and it has 39")
	}
	if snap.Me.Email == "" {
		t.Error("no identity: read.sh me returned nothing")
	}
	for _, b := range snap.Briefs {
		if b.Serial == "" || b.Slug == "" {
			t.Errorf("brief with no serial or slug: %+v", b)
		}
	}
}

// TestPeerEventsAreMarkedSynthetic asserts the field the UI must never drop.
func TestPeerEventsAreMarkedSynthetic(t *testing.T) {
	root := repoRootForTest(t)
	rd := NewReader(root)
	if _, err := os.Stat(rd.PeerSH); err != nil {
		t.Skipf("peer source absent: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	evs, err := PeerOnce(ctx, rd)
	if err != nil {
		t.Fatalf("peer events: %v", err)
	}
	if len(evs) == 0 {
		t.Fatal("peer-events.sh printed nothing")
	}
	for _, e := range evs {
		if !e.Synthetic {
			t.Errorf("peer event %s is not marked synthetic", e.SHA)
		}
		if e.Mine {
			t.Errorf("peer event %s claims to be mine", e.SHA)
		}
	}
}

// TestUnmarkedPeerEventIsRefused covers the failure the fixture's README names: a peer event
// shown as real. The decoder refuses rather than the UI forgetting.
func TestUnmarkedPeerEventIsRefused(t *testing.T) {
	_, err := DecodePeerEvent([]byte(`{"sha":"dead","who":"x@y.test","mine":false,"kind":"phase","serial":"","phase":"","subject":"s"}`))
	if err == nil {
		t.Fatal("an event with no synthetic flag was accepted")
	}
	if !strings.Contains(err.Error(), "synthetic") {
		t.Errorf("unhelpful error: %v", err)
	}
}

func TestUnknownFieldStopsTheDecode(t *testing.T) {
	_, err := DecodeEvents([]byte(`[{"sha":"a","when":"","who":"","mine":false,"kind":"code","serial":"","phase":"","subject":"s","surprise":1}]`))
	if err == nil {
		t.Fatal("an unknown field decoded quietly; drift in read.sh would go unnoticed")
	}
}

func TestStateNameAndPointer(t *testing.T) {
	cases := []struct{ in, name, ptr string }{
		{"done(PR#11)", "done", "PR#11"},
		{"in-progress(blic/bake-off)", "in-progress", "blic/bake-off"},
		{"skipped", "skipped", ""},
		{"done(commit 92a7168)", "done", "commit 92a7168"},
	}
	for _, c := range cases {
		if got := StateName(c.in); got != c.name {
			t.Errorf("StateName(%q) = %q, want %q", c.in, got, c.name)
		}
		if got := StatePointer(c.in); got != c.ptr {
			t.Errorf("StatePointer(%q) = %q, want %q", c.in, got, c.ptr)
		}
	}
}

func TestNextActionShapes(t *testing.T) {
	closedDefect := []Defect{{Clause: "BRIEFS-11", Message: "status line says done, and ledger.md records no **Closed:** date"}}
	cases := []struct {
		name   string
		brief  Brief
		defs   []Defect
		action string
	}{
		{
			"done with no closed date wants the closeout",
			Brief{State: "done(PR#125)", HasLedger: true},
			closedDefect,
			"blc-close-brief",
		},
		{
			"a filed serial with no ledger wants a start",
			Brief{State: "planned", HasLedger: false},
			nil,
			"blc-start-brief",
		},
		{
			"a phase in progress with a pointer wants a review",
			Brief{State: "in-progress", HasLedger: true, Phases: []Phase{{ID: "a", State: "in-progress", Pointer: "blic/bake-off"}}},
			nil,
			"blc-review-pr then blc-commit-push-pr",
		},
		{
			"every phase finished and the brief still open wants the closeout",
			Brief{State: "in-progress", HasLedger: true, Phases: []Phase{{ID: "a", State: "done"}}},
			nil,
			"blc-close-brief",
		},
		{
			"a state this console does not know is reported, not guessed",
			Brief{State: "in-progress", HasLedger: true, Phases: []Phase{{ID: "a", State: "pending"}}},
			nil,
			"none derivable",
		},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, why := c.brief.NextAction(c.defs)
			if got != c.action {
				t.Errorf("NextAction = %q (%s), want %q", got, why, c.action)
			}
			if why == "" {
				t.Error("no reason given; a derived action with no evidence is a guess")
			}
		})
	}
}

func TestAttentionPutsMineAndOpenFirst(t *testing.T) {
	briefs := []Brief{
		{Serial: "0001", State: "done", Mine: true},
		{Serial: "0002", State: "in-progress", Mine: false},
		{Serial: "0003", State: "in-progress", Mine: true},
	}
	got := Attention(briefs, nil)
	if got[0].Serial != "0003" {
		t.Errorf("first is %s, want 0003 (mine and in flight)", got[0].Serial)
	}
}

func TestDefectsForMatchesBySlug(t *testing.T) {
	b := Brief{Serial: "0028", Slug: "0028-the-summary-with-no-writer"}
	all := []Defect{
		{Subject: "0028-the-summary-with-no-writer", Clause: "BRIEFS-11"},
		{Subject: "0027-something-else", Clause: "BRIEFS-11"},
	}
	if got := DefectsFor(b, all); len(got) != 1 {
		t.Errorf("matched %d defects, want 1", len(got))
	}
}

func TestReaderPathsPointAtTheInstrument(t *testing.T) {
	rd := NewReader("/tmp/x")
	if rd.ReadSH != filepath.Join("/tmp/x", "experiments", "blic", "read.sh") {
		t.Errorf("read.sh path is %s", rd.ReadSH)
	}
}
