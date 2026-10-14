package record

import (
	"bufio"
	"bytes"
	"context"
	"os/exec"
	"strings"
)

// PeerOnce runs `peer-events.sh` with no arguments: the fixed set, once. The set is fixed on
// purpose so two prototypes see the same events in the same order.
func PeerOnce(ctx context.Context, r *Reader) ([]Event, error) {
	cmd := exec.CommandContext(ctx, "bash", r.PeerSH)
	cmd.Dir = r.Dir
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return nil, err
	}
	var evs []Event
	for _, line := range strings.Split(strings.TrimSpace(out.String()), "\n") {
		if strings.TrimSpace(line) == "" {
			continue
		}
		ev, err := DecodePeerEvent([]byte(line))
		if err != nil {
			return nil, err
		}
		evs = append(evs, ev)
	}
	return evs, nil
}

// PeerStream runs `peer-events.sh --stream` and delivers each line as a typed Event.
//
// It is a subprocess, not a daemon: it lives and dies with the console, holds no state and
// listens on nothing. The brief rules out a service, and the distinction worth keeping is
// that nothing survives the console quitting.
type PeerStream struct {
	Events chan Event
	Errors chan error

	cmd *exec.Cmd
}

// StartPeerStream launches the stream. Cancelling ctx kills the subprocess.
func StartPeerStream(ctx context.Context, r *Reader) (*PeerStream, error) {
	cmd := exec.CommandContext(ctx, "bash", r.PeerSH, "--stream")
	cmd.Dir = r.Dir
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	ps := &PeerStream{
		Events: make(chan Event, 16),
		Errors: make(chan error, 4),
		cmd:    cmd,
	}
	go func() {
		defer close(ps.Events)
		sc := bufio.NewScanner(stdout)
		for sc.Scan() {
			line := sc.Bytes()
			if len(line) == 0 {
				continue
			}
			ev, err := DecodePeerEvent(line)
			if err != nil {
				select {
				case ps.Errors <- err:
				default:
				}
				continue
			}
			ps.Events <- ev
		}
		_ = cmd.Wait()
	}()
	return ps, nil
}
