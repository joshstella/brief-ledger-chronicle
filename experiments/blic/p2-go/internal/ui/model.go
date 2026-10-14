package ui

import (
	"context"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"blic/p2go/internal/record"
)

// Focus names the pane that takes movement keys.
type Focus int

const (
	FocusList Focus = iota
	FocusDetail
	FocusFeed
)

// Filter is the brief list's view. Mine-and-open is the default because the brief's first
// question is "what is mine to do next" and a 39-brief list does not answer it.
type Filter int

const (
	FilterMineOpen Filter = iota
	FilterOpen
	FilterMine
	FilterDefective
	FilterAll
)

func (f Filter) String() string {
	switch f {
	case FilterMineOpen:
		return "mine, in flight"
	case FilterOpen:
		return "in flight"
	case FilterMine:
		return "mine"
	case FilterDefective:
		return "flagged by the gate"
	default:
		return "all"
	}
}

func (f Filter) keep(b record.Brief, defects []record.Defect) bool {
	switch f {
	case FilterMineOpen:
		return b.Mine && b.Open()
	case FilterOpen:
		return b.Open()
	case FilterMine:
		return b.Mine
	case FilterDefective:
		return len(record.DefectsFor(b, defects)) > 0
	default:
		return true
	}
}

// Options configure a Model from main.
type Options struct {
	Reader       *record.Reader
	Peer         *record.PeerStream
	PeerNote     string // what the status bar says about the peer source
	RefreshEvery time.Duration
	FullEvery    time.Duration
	Plain        bool // capture mode: no ANSI, no alt screen
}

// Model is the whole console. Bubble Tea's one-model shape is kept on purpose: the panes
// share a cursor, a filter and a snapshot, and splitting them into three models would mean
// three copies of the same selection.
type Model struct {
	rd   *record.Reader
	peer *record.PeerStream

	snap     *record.Snapshot
	loadDur  time.Duration
	loadedAt time.Time
	loading  bool
	err      string
	peerErr  string

	width, height int
	focus         Focus
	filter        Filter
	search        string
	searching     bool
	help          bool

	cursor       int
	detailScroll int
	feedCursor   int

	feed      []record.Event
	seen      map[string]bool
	arrived   int // events seen after the first snapshot: "what changed that I did not do"
	showSynth bool

	// Two cadences, because the instrument's cost is not evenly spread. `read.sh events`
	// is 0.3s and `read.sh snapshot` is 3.1s on this fixture, almost all of it
	// tools/validate-briefs.sh. A console that ran the whole snapshot on the event cadence
	// would hold 15% of a core all day to notice a commit. So events poll often and the
	// rest polls rarely, and r forces the whole thing.
	refreshEvery time.Duration
	fullEvery    time.Duration
	eventsAt     time.Time
	now          time.Time
	plain        bool
	peerNote     string
}

// New builds the model. It does not read anything; Init does.
func New(o Options) Model {
	if o.RefreshEvery <= 0 {
		o.RefreshEvery = 20 * time.Second
	}
	if o.FullEvery <= 0 {
		o.FullEvery = 5 * time.Minute
	}
	return Model{
		rd:           o.Reader,
		peer:         o.Peer,
		filter:       FilterMineOpen,
		showSynth:    true,
		seen:         map[string]bool{},
		refreshEvery: o.RefreshEvery,
		fullEvery:    o.FullEvery,
		width:        100,
		height:       32,
		now:          time.Now(),
		plain:        o.Plain,
		peerNote:     o.PeerNote,
		loading:      true,
	}
}

// ── messages ────────────────────────────────────────────────────────────────

type snapshotMsg struct {
	snap *record.Snapshot
	dur  time.Duration
	err  error
}
type eventsMsg struct {
	events []record.Event
	err    error
}
type peerMsg struct{ ev record.Event }
type peerErrMsg struct{ err error }
type tickMsg time.Time

func (m Model) loadSnapshot() tea.Cmd {
	rd := m.rd
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()
		snap, dur, err := rd.Snapshot(ctx)
		return snapshotMsg{snap: snap, dur: dur, err: err}
	}
}

func (m Model) loadEvents() tea.Cmd {
	rd := m.rd
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		evs, err := rd.Events(ctx, "")
		return eventsMsg{events: evs, err: err}
	}
}

func (m Model) waitForPeer() tea.Cmd {
	if m.peer == nil {
		return nil
	}
	peer := m.peer
	return func() tea.Msg {
		select {
		case ev, ok := <-peer.Events:
			if !ok {
				return nil
			}
			return peerMsg{ev}
		case err := <-peer.Errors:
			return peerErrMsg{err}
		}
	}
}

func tick(d time.Duration) tea.Cmd {
	return tea.Tick(d, func(t time.Time) tea.Msg { return tickMsg(t) })
}

// Init starts the first read, the clock and the peer listener.
func (m Model) Init() tea.Cmd {
	return tea.Batch(m.loadSnapshot(), tick(time.Second), m.waitForPeer())
}

// ── update ──────────────────────────────────────────────────────────────────

// Update is the whole key map. Keys are single letters with vi movement because this console
// is meant to be alt-tabbed into for four seconds at a time.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {

	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		return m, nil

	case tickMsg:
		m.now = time.Time(msg)
		var cmds []tea.Cmd
		cmds = append(cmds, tick(time.Second))
		if !m.loading && m.snap != nil {
			switch {
			case time.Since(m.loadedAt) >= m.fullEvery:
				m.loading = true
				cmds = append(cmds, m.loadSnapshot())
			case time.Since(m.eventsAt) >= m.refreshEvery:
				m.eventsAt = time.Now()
				cmds = append(cmds, m.loadEvents())
			}
		}
		return m, tea.Batch(cmds...)

	case eventsMsg:
		if msg.err != nil {
			m.err = msg.err.Error()
			return m, nil
		}
		m.mergeReal(msg.events, false)
		return m, nil

	case snapshotMsg:
		m.loading = false
		m.loadDur = msg.dur
		m.loadedAt = time.Now()
		m.eventsAt = m.loadedAt
		if msg.err != nil {
			m.err = msg.err.Error()
			return m, nil
		}
		m.err = ""
		first := m.snap == nil
		m.snap = msg.snap
		m.mergeReal(msg.snap.Events, first)
		m.clampCursor()
		return m, nil

	case peerMsg:
		m.pushEvent(msg.ev)
		return m, m.waitForPeer()

	case peerErrMsg:
		m.peerErr = msg.err.Error()
		return m, m.waitForPeer()

	case tea.KeyMsg:
		return m.key(msg)
	}
	return m, nil
}

func (m Model) key(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	// The search box owns every key while it is open, apart from the two that close it.
	if m.searching {
		switch msg.Type {
		case tea.KeyEsc:
			m.searching, m.search = false, ""
		case tea.KeyEnter:
			m.searching = false
		case tea.KeyBackspace:
			if m.search != "" {
				m.search = m.search[:len(m.search)-1]
			}
		case tea.KeyRunes, tea.KeySpace:
			m.search += msg.String()
		}
		m.cursor = 0
		m.clampCursor()
		return m, nil
	}

	switch msg.String() {
	case "q", "ctrl+c":
		return m, tea.Quit
	case "?":
		m.help = !m.help
	case "esc":
		m.help = false
	case "tab":
		m.focus = (m.focus + 1) % 3
	case "shift+tab":
		m.focus = (m.focus + 2) % 3
	case "enter":
		m.focus = FocusDetail
	case "r":
		if !m.loading {
			m.loading = true
			return m, m.loadSnapshot()
		}
	case "f":
		m.filter = (m.filter + 1) % 5
		m.cursor = 0
	case "1":
		m.filter, m.cursor = FilterMineOpen, 0
	case "2":
		m.filter, m.cursor = FilterOpen, 0
	case "3":
		m.filter, m.cursor = FilterMine, 0
	case "4":
		m.filter, m.cursor = FilterDefective, 0
	case "5":
		m.filter, m.cursor = FilterAll, 0
	case "/":
		m.searching = true
	case "s":
		m.showSynth = !m.showSynth
		m.feedCursor = 0
	case "a":
		m.arrived = 0 // acknowledge: the "what changed" counter is a thing you clear
	case "j", "down":
		m.move(1)
	case "k", "up":
		m.move(-1)
	case "g":
		m.jump(0)
	case "G":
		m.jump(1 << 30)
	case "pgdown", "ctrl+d":
		m.move(10)
	case "pgup", "ctrl+u":
		m.move(-10)
	}
	m.clampCursor()
	return m, nil
}

func (m *Model) move(n int) {
	switch m.focus {
	case FocusList:
		m.cursor += n
		m.detailScroll = 0
	case FocusDetail:
		m.detailScroll += n
	case FocusFeed:
		m.feedCursor += n
	}
}

func (m *Model) jump(to int) {
	switch m.focus {
	case FocusList:
		m.cursor = to
		m.detailScroll = 0
	case FocusDetail:
		m.detailScroll = to
	case FocusFeed:
		m.feedCursor = to
	}
}

func (m *Model) clampCursor() {
	n := len(m.visible())
	if m.cursor >= n {
		m.cursor = n - 1
	}
	if m.cursor < 0 {
		m.cursor = 0
	}
	if m.detailScroll < 0 {
		m.detailScroll = 0
	}
	f := len(m.visibleFeed())
	if m.feedCursor >= f {
		m.feedCursor = f - 1
	}
	if m.feedCursor < 0 {
		m.feedCursor = 0
	}
}

// ── event feed ──────────────────────────────────────────────────────────────

// mergeReal folds a snapshot's git events into the feed. On the first load everything is
// marked seen: a console that opens claiming forty things changed while you were away has
// told you nothing. After that, anything new is counted, which is the brief's second question.
func (m *Model) mergeReal(evs []record.Event, first bool) {
	for i := len(evs) - 1; i >= 0; i-- {
		ev := evs[i]
		if m.seen[ev.SHA] {
			continue
		}
		m.seen[ev.SHA] = true
		m.feed = append([]record.Event{ev}, m.feed...)
		if !first && !ev.Mine {
			m.arrived++
		}
	}
	if len(m.feed) > 400 {
		m.feed = m.feed[:400]
	}
}

func (m *Model) pushEvent(ev record.Event) {
	m.feed = append([]record.Event{ev}, m.feed...)
	if !ev.Mine {
		m.arrived++
	}
	if len(m.feed) > 400 {
		m.feed = m.feed[:400]
	}
}

func (m Model) visibleFeed() []record.Event {
	if m.showSynth {
		return m.feed
	}
	out := make([]record.Event, 0, len(m.feed))
	for _, e := range m.feed {
		if !e.Synthetic {
			out = append(out, e)
		}
	}
	return out
}

// ── brief list ──────────────────────────────────────────────────────────────

func (m Model) visible() []record.Brief {
	if m.snap == nil {
		return nil
	}
	ordered := record.Attention(m.snap.Briefs, m.snap.Defects)
	out := make([]record.Brief, 0, len(ordered))
	q := strings.ToLower(strings.TrimSpace(m.search))
	for _, b := range ordered {
		if !m.filter.keep(b, m.snap.Defects) {
			continue
		}
		if q != "" && !strings.Contains(strings.ToLower(b.Serial+" "+b.Title+" "+b.Slug+" "+b.Assignee), q) {
			continue
		}
		out = append(out, b)
	}
	return out
}

func (m Model) selected() *record.Brief {
	v := m.visible()
	if m.cursor < 0 || m.cursor >= len(v) {
		return nil
	}
	return &v[m.cursor]
}
