package record

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Reader shells out to the frozen read surface. The contract for the bake-off is the script,
// not the files, so this package never opens docs/blc itself.
type Reader struct {
	ReadSH string // path to experiments/blic/read.sh
	PeerSH string // path to experiments/blic/peer-events.sh
	Dir    string // repository root, the cwd read.sh expects
}

// NewReader locates the instrument from a repository checkout.
func NewReader(repoRoot string) *Reader {
	return &Reader{
		ReadSH: filepath.Join(repoRoot, "experiments", "blic", "read.sh"),
		PeerSH: filepath.Join(repoRoot, "experiments", "blic", "peer-events.sh"),
		Dir:    repoRoot,
	}
}

// RepoRoot asks git, the same way read.sh does.
func RepoRoot(start string) (string, error) {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	cmd.Dir = start
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("not a git checkout at %s: %w", start, err)
	}
	return strings.TrimSpace(string(out)), nil
}

func (r *Reader) run(ctx context.Context, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, "bash", append([]string{r.ReadSH}, args...)...)
	cmd.Dir = r.Dir
	var stdout, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	if err := cmd.Run(); err != nil {
		msg := strings.TrimSpace(stderr.String())
		if msg == "" {
			msg = err.Error()
		}
		return nil, fmt.Errorf("read.sh %s: %s", strings.Join(args, " "), msg)
	}
	return stdout.Bytes(), nil
}

// Snapshot runs `read.sh snapshot` and decodes it strictly.
func (r *Reader) Snapshot(ctx context.Context) (*Snapshot, time.Duration, error) {
	start := time.Now()
	raw, err := r.run(ctx, "snapshot")
	if err != nil {
		return nil, time.Since(start), err
	}
	snap, err := DecodeSnapshot(raw)
	return snap, time.Since(start), err
}

// Events runs `read.sh events --since X`.
func (r *Reader) Events(ctx context.Context, since string) ([]Event, error) {
	args := []string{"events"}
	if since != "" {
		args = append(args, "--since", since)
	}
	raw, err := r.run(ctx, args...)
	if err != nil {
		return nil, err
	}
	return DecodeEvents(raw)
}

// DecodeSnapshot rejects unknown fields. read.sh has no schema and no tests; a field it grows
// should stop this console rather than vanish into an ignored key.
func DecodeSnapshot(raw []byte) (*Snapshot, error) {
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	var s Snapshot
	if err := dec.Decode(&s); err != nil {
		return nil, fmt.Errorf("decoding read.sh snapshot: %w", err)
	}
	return &s, nil
}

// DecodeEvents decodes a `read.sh events` array.
func DecodeEvents(raw []byte) ([]Event, error) {
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	var e []Event
	if err := dec.Decode(&e); err != nil {
		return nil, fmt.Errorf("decoding read.sh events: %w", err)
	}
	return e, nil
}

// DecodePeerEvent decodes one line of peer-events.sh.
//
// It asserts Synthetic rather than trusting it. peer-events.sh promises the field on every
// line; if a line arrives without it this console would show a peer event as real, which is
// the one failure the fixture's README names. Failing loudly is the cheaper mistake.
func DecodePeerEvent(line []byte) (Event, error) {
	dec := json.NewDecoder(bytes.NewReader(line))
	dec.DisallowUnknownFields()
	var e Event
	if err := dec.Decode(&e); err != nil {
		return e, fmt.Errorf("decoding peer event: %w", err)
	}
	if !e.Synthetic {
		return e, fmt.Errorf("peer event %q arrived without \"synthetic\": true; refusing to show it as real", e.SHA)
	}
	return e, nil
}
