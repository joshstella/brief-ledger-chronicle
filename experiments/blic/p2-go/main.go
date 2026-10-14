// Command blic is prototype 2 of the #0039 bake-off: a read-only console over the BLC
// record, built as one static binary.
//
// It reads through experiments/blic/read.sh and experiments/blic/peer-events.sh. It never
// writes a record, never pushes, and never calls a forge. It holds no state between runs.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"blic/p2go/internal/record"
	"blic/p2go/internal/ui"
)

func main() {
	var (
		repoFlag = flag.String("repo", ".", "path inside the repository checkout to read")
		refresh  = flag.Duration("refresh", 20*time.Second, "how often to reread events (read.sh events, 0.3s on this fixture)")
		full     = flag.Duration("full-refresh", 5*time.Minute, "how often to reread everything (read.sh snapshot, 3.1s: it runs the gate)")
		noPeer   = flag.Bool("no-peer", false, "do not run peer-events.sh (the fixture has one author, so the feed will be all yours)")
		capture  = flag.String("capture", "", "render plain-text frames instead of running: a comma-separated key script, e.g. 'j,enter,peer:0'")
		session  = flag.String("session", "", "run the real program against a scripted input stream with no terminal, and print the last frame")
		hold     = flag.Duration("hold", 2*time.Second, "pause between scripted keys in -session")
		width    = flag.Int("width", 120, "capture width")
		height   = flag.Int("height", 40, "capture height")
	)
	flag.Parse()

	root, err := record.RepoRoot(*repoFlag)
	if err != nil {
		die(err)
	}
	rd := record.NewReader(root)
	if _, err := os.Stat(rd.ReadSH); err != nil {
		die(fmt.Errorf("the read surface is missing at %s: this prototype only runs on the bake-off branch", rd.ReadSH))
	}

	opts := ui.Options{Reader: rd, RefreshEvery: *refresh, FullEvery: *full}

	if *capture != "" {
		if err := ui.Capture(os.Stdout, opts, *capture, *width, *height); err != nil {
			die(err)
		}
		return
	}

	// The peer stream is a child process, not a service: it dies with this context, which
	// dies with the program.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	if !*noPeer {
		peer, err := record.StartPeerStream(ctx, rd)
		if err != nil {
			die(err)
		}
		opts.Peer = peer
	}

	if *session != "" {
		if err := ui.Session(os.Stdout, opts, *session, *width, *height, *hold); err != nil {
			die(err)
		}
		return
	}

	p := tea.NewProgram(ui.New(opts), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		die(err)
	}
}

func die(err error) {
	fmt.Fprintln(os.Stderr, "blic:", err)
	os.Exit(1)
}
