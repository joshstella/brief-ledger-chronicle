// Package record holds the typed boundary over experiments/blic/read.sh.
//
// read.sh publishes no schema. It emits JSON from printf format strings, one per record
// type, and those format strings are the only contract there is. Each struct below cites
// the line in read.sh that writes it, so drift is found by reading two places rather than
// by guessing which one is right. decode.go rejects unknown fields, so a field added to
// read.sh fails the decode instead of being dropped in silence.
package record

// Identity is read.sh:260 — cmd_me.
type Identity struct {
	Email string `json:"email"`
}

// Phase is read.sh:121-122. State and Label come from different files and are allowed to
// disagree: the status line carries the state, the ledger table carries the label. That
// disagreement is BRIEFS-9 and the instrument reports it rather than resolving it.
type Phase struct {
	ID      string `json:"id"`
	Label   string `json:"label"`
	State   string `json:"state"`
	Pointer string `json:"pointer"`
}

// Brief is read.sh:88-127 — emit_brief.
type Brief struct {
	Serial     string  `json:"serial"`
	Slug       string  `json:"slug"`
	Dir        string  `json:"dir"`
	Title      string  `json:"title"`
	State      string  `json:"state"`
	StatusLine string  `json:"status_line"`
	Owner      string  `json:"owner"`
	Author     string  `json:"author"`
	Assignee   string  `json:"assignee"`
	Mine       bool    `json:"mine"`
	Created    string  `json:"created"`
	Closed     string  `json:"closed"`
	Touched    string  `json:"touched"`
	HasLedger  bool    `json:"has_ledger"`
	Phases     []Phase `json:"phases"`
}

// Declaration is read.sh:158-169 — a `##` entry in docs/blc/state/<email>.md.
type Declaration struct {
	Who     string   `json:"who"`
	Mine    bool     `json:"mine"`
	Touched string   `json:"touched"`
	Claims  []string `json:"claims"`
}

// Defect is read.sh:193-194 — one line of tools/validate-briefs.sh, parsed not re-derived.
type Defect struct {
	Clause  string `json:"clause"`
	Kind    string `json:"kind"`
	Subject string `json:"subject"`
	Message string `json:"message"`
}

// Event is read.sh:250-253 for real events, and peer-events.sh for synthetic ones.
//
// The two sources do not emit the same fields. peer-events.sh carries `synthetic` and omits
// `when` and `mine` is always false; read.sh carries `when` and never carries `synthetic`.
// One struct covers both because the console shows them in one feed, and Synthetic is the
// field the UI must never drop: an unmarked synthetic event is a lie about the record.
type Event struct {
	SHA       string `json:"sha"`
	When      string `json:"when"`
	Who       string `json:"who"`
	Mine      bool   `json:"mine"`
	Kind      string `json:"kind"`
	Serial    string `json:"serial"`
	Phase     string `json:"phase"`
	Subject   string `json:"subject"`
	Synthetic bool   `json:"synthetic"`
}

// Snapshot is read.sh:262-273 — cmd_snapshot.
type Snapshot struct {
	Generated    string        `json:"generated"`
	Repo         string        `json:"repo"`
	Me           Identity      `json:"me"`
	Head         string        `json:"head"`
	Branch       string        `json:"branch"`
	Briefs       []Brief       `json:"briefs"`
	Declarations []Declaration `json:"declarations"`
	Defects      []Defect      `json:"defects"`
	Events       []Event       `json:"events"`
}
