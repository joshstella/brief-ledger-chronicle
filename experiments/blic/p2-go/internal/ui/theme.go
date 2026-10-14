package ui

import "github.com/charmbracelet/lipgloss"

// One palette, defined once. Every colour in the console means a state, not a mood: the
// reader should be able to learn four colours and then stop reading the legend.
var (
	colFg     = lipgloss.AdaptiveColor{Light: "236", Dark: "252"}
	colDim    = lipgloss.AdaptiveColor{Light: "245", Dark: "243"}
	colAccent = lipgloss.AdaptiveColor{Light: "25", Dark: "81"}   // mine, focus
	colFlight = lipgloss.AdaptiveColor{Light: "130", Dark: "214"} // in flight
	colDefect = lipgloss.AdaptiveColor{Light: "124", Dark: "203"} // the gate's judgments
	colDone   = lipgloss.AdaptiveColor{Light: "28", Dark: "78"}
	colSynth  = lipgloss.AdaptiveColor{Light: "90", Dark: "177"} // synthetic, never anything else
	colBarBg  = lipgloss.AdaptiveColor{Light: "254", Dark: "236"}
	colSelBg  = lipgloss.AdaptiveColor{Light: "253", Dark: "238"}
)

var (
	styBase     = lipgloss.NewStyle().Foreground(colFg)
	styDim      = lipgloss.NewStyle().Foreground(colDim)
	styAccent   = lipgloss.NewStyle().Foreground(colAccent)
	styAccentB  = lipgloss.NewStyle().Foreground(colAccent).Bold(true)
	styFlight   = lipgloss.NewStyle().Foreground(colFlight)
	styFlightB  = lipgloss.NewStyle().Foreground(colFlight).Bold(true)
	styDefect   = lipgloss.NewStyle().Foreground(colDefect)
	styDefectB  = lipgloss.NewStyle().Foreground(colDefect).Bold(true)
	styDone     = lipgloss.NewStyle().Foreground(colDone)
	stySynth    = lipgloss.NewStyle().Foreground(colSynth)
	stySynthTag = lipgloss.NewStyle().Foreground(colSynth).Bold(true)
	stySelected = lipgloss.NewStyle().Background(colSelBg).Foreground(colFg)
	styBar      = lipgloss.NewStyle().Background(colBarBg).Foreground(colFg)
	styTitle    = lipgloss.NewStyle().Bold(true).Foreground(colFg)
	styKey      = lipgloss.NewStyle().Foreground(colAccent).Bold(true)
)

// paneBorder marks focus with the border colour. A focused pane is the only one that takes
// j/k, and the reader should not have to press a key to find out which one that is.
func paneBorder(focused bool) lipgloss.Style {
	s := lipgloss.NewStyle().Border(lipgloss.RoundedBorder())
	if focused {
		return s.BorderForeground(colAccent)
	}
	return s.BorderForeground(colDim)
}

// stateStyle maps a BLC phase or brief state word to its colour.
func stateStyle(state string) lipgloss.Style {
	switch state {
	case "done":
		return styDone
	case "in-progress":
		return styFlightB
	case "blocked":
		return styDefectB
	case "planned":
		return styAccent
	case "skipped", "abandoned", "superseded":
		return styDim
	case "no-line":
		return styDefect
	default:
		return styBase
	}
}
