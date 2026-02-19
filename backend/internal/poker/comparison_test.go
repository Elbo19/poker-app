package poker

import (
	"testing"
)

// TestCompareHandsComprehensive tests all poker hand comparisons
func TestCompareHandsComprehensive(t *testing.T) {
	tests := []struct {
		name     string
		player1  []string
		player2  []string
		expected int // 1 = player1 wins, -1 = player2 wins, 0 = tie
	}{
		// Royal Flush tests
		{
			name:     "Royal Flush vs Royal Flush - Tie",
			player1:  []string{"HA", "HK", "HQ", "HJ", "HT"},
			player2:  []string{"SA", "SK", "SQ", "SJ", "ST"},
			expected: 0,
		},
		{
			name:     "Royal Flush vs Straight Flush",
			player1:  []string{"HA", "HK", "HQ", "HJ", "HT"},
			player2:  []string{"D9", "D8", "D7", "D6", "D5"},
			expected: 1,
		},

		// Straight Flush tests
		{
			name:     "Higher Straight Flush wins",
			player1:  []string{"D9", "D8", "D7", "D6", "D5"},
			player2:  []string{"C8", "C7", "C6", "C5", "C4"},
			expected: 1,
		},
		{
			name:     "Straight Flush vs Four of a Kind",
			player1:  []string{"D9", "D8", "D7", "D6", "D5"},
			player2:  []string{"SA", "HA", "DA", "CA", "SK"},
			expected: 1,
		},

		// Four of a Kind tests
		{
			name:     "Higher Four of a Kind wins",
			player1:  []string{"SA", "HA", "DA", "CA", "SK"},
			player2:  []string{"SK", "HK", "DK", "CK", "SQ"},
			expected: 1,
		},
		{
			name:     "Same Four of a Kind - Higher kicker wins",
			player1:  []string{"SA", "HA", "DA", "CA", "SK"},
			player2:  []string{"SA", "HA", "DA", "CA", "SQ"},
			expected: 1,
		},
		{
			name:     "Four of a Kind vs Full House",
			player1:  []string{"SA", "HA", "DA", "CA", "SK"},
			player2:  []string{"SQ", "HQ", "DQ", "CK", "SK"},
			expected: 1,
		},

		// Full House tests
		{
			name:     "Higher trips in Full House wins",
			player1:  []string{"SA", "HA", "DA", "CK", "SK"},
			player2:  []string{"SQ", "HQ", "DQ", "CK", "SK"},
			expected: 1,
		},
		{
			name:     "Same trips - Higher pair wins",
			player1:  []string{"SA", "HA", "DA", "CK", "SK"},
			player2:  []string{"SA", "HA", "DA", "CQ", "SQ"},
			expected: 1,
		},
		{
			name:     "Full House vs Flush",
			player1:  []string{"SA", "HA", "DA", "CK", "SK"},
			player2:  []string{"S2", "S4", "S6", "S8", "ST"},
			expected: 1,
		},

		// Flush tests
		{
			name:     "Higher flush card wins",
			player1:  []string{"SA", "SK", "SQ", "S9", "S7"},
			player2:  []string{"HA", "HK", "HQ", "H9", "H6"},
			expected: 1,
		},
		{
			name:     "Flush - second card matters",
			player1:  []string{"SA", "SK", "SQ", "S9", "S7"},
			player2:  []string{"HA", "HK", "HJ", "H9", "H8"},
			expected: 1,
		},
		{
			name:     "Flush vs Straight",
			player1:  []string{"S2", "S4", "S6", "S8", "ST"},
			player2:  []string{"SA", "HK", "DQ", "CJ", "ST"},
			expected: 1,
		},

		// Straight tests
		{
			name:     "Higher straight wins",
			player1:  []string{"SA", "HK", "DQ", "CJ", "ST"},
			player2:  []string{"SK", "HQ", "DJ", "CT", "S9"},
			expected: 1,
		},
		{
			name:     "Straight vs Wheel - Regular straight wins",
			player1:  []string{"S6", "H5", "D4", "C3", "S2"},
			player2:  []string{"SA", "H5", "D4", "C3", "S2"},
			expected: 1,
		},
		{
			name:     "Straight vs Three of a Kind",
			player1:  []string{"SA", "HK", "DQ", "CJ", "ST"},
			player2:  []string{"SA", "HA", "DA", "CK", "SQ"},
			expected: 1,
		},

		// Three of a Kind tests
		{
			name:     "Higher Three of a Kind wins",
			player1:  []string{"SA", "HA", "DA", "CK", "SQ"},
			player2:  []string{"SK", "HK", "DK", "CQ", "SJ"},
			expected: 1,
		},
		{
			name:     "Same trips - Higher kicker wins",
			player1:  []string{"SA", "HA", "DA", "CK", "SQ"},
			player2:  []string{"SA", "HA", "DA", "CQ", "SJ"},
			expected: 1,
		},
		{
			name:     "Same trips - First kicker same, second kicker wins",
			player1:  []string{"SA", "HA", "DA", "CK", "SQ"},
			player2:  []string{"SA", "HA", "DA", "CK", "SJ"},
			expected: 1,
		},
		{
			name:     "Three of a Kind vs Two Pair",
			player1:  []string{"SA", "HA", "DA", "CK", "SQ"},
			player2:  []string{"SA", "HA", "DK", "CK", "SQ"},
			expected: 1,
		},

		// Two Pair tests
		{
			name:     "Higher top pair wins",
			player1:  []string{"SA", "HA", "DK", "CK", "SQ"},
			player2:  []string{"SQ", "HQ", "DJ", "CJ", "ST"},
			expected: 1,
		},
		{
			name:     "Same top pair - Higher second pair wins",
			player1:  []string{"SA", "HA", "DK", "CK", "SQ"},
			player2:  []string{"SA", "HA", "DQ", "CQ", "SJ"},
			expected: 1,
		},
		{
			name:     "Same both pairs - Higher kicker wins",
			player1:  []string{"SA", "HA", "DK", "CK", "SQ"},
			player2:  []string{"SA", "HA", "DK", "CK", "SJ"},
			expected: 1,
		},
		{
			name:     "Two Pair vs One Pair",
			player1:  []string{"SA", "HA", "DK", "CK", "SQ"},
			player2:  []string{"SA", "HA", "DK", "CQ", "SJ"},
			expected: 1,
		},

		// One Pair tests
		{
			name:     "Higher pair wins",
			player1:  []string{"SA", "HA", "DK", "CQ", "SJ"},
			player2:  []string{"SK", "HK", "DQ", "CJ", "ST"},
			expected: 1,
		},
		{
			name:     "Same pair - Higher first kicker wins",
			player1:  []string{"SA", "HA", "DK", "CQ", "SJ"},
			player2:  []string{"SA", "HA", "DQ", "CJ", "ST"},
			expected: 1,
		},
		{
			name:     "Same pair - First kicker same, second kicker wins",
			player1:  []string{"SA", "HA", "DK", "CQ", "SJ"},
			player2:  []string{"SA", "HA", "DK", "CJ", "ST"},
			expected: 1,
		},
		{
			name:     "Same pair - Third kicker wins",
			player1:  []string{"SA", "HA", "DK", "CQ", "SJ"},
			player2:  []string{"SA", "HA", "DK", "CQ", "ST"},
			expected: 1,
		},
		{
			name:     "One Pair vs High Card",
			player1:  []string{"SA", "HA", "DK", "CQ", "SJ"},
			player2:  []string{"SA", "HK", "DQ", "CJ", "S9"},
			expected: 1,
		},

		// High Card tests
		{
			name:     "Higher high card wins",
			player1:  []string{"SA", "HK", "DQ", "CJ", "S9"},
			player2:  []string{"SK", "HQ", "DJ", "CT", "S8"},
			expected: 1,
		},
		{
			name:     "Same high card - Second card wins",
			player1:  []string{"SA", "HK", "DQ", "CJ", "S9"},
			player2:  []string{"SA", "HQ", "DJ", "CT", "S8"},
			expected: 1,
		},
		{
			name:     "All cards same - Tie",
			player1:  []string{"SA", "HK", "DQ", "CJ", "S9"},
			player2:  []string{"HA", "DK", "CQ", "SJ", "H9"},
			expected: 0,
		},

		// Edge cases with 7 cards (Texas Hold'em scenario)
		{
			name:     "7 cards - Best 5 card hand wins",
			player1:  []string{"SA", "HA", "DK", "CK", "SQ", "H3", "D2"},
			player2:  []string{"SA", "HA", "DQ", "CQ", "SJ", "H5", "D4"},
			expected: 1,
		},
		{
			name:     "7 cards - Full House beats Two Pair",
			player1:  []string{"SA", "HA", "DA", "CK", "SK", "H3", "D2"},
			player2:  []string{"SQ", "HQ", "DJ", "CJ", "ST", "H5", "D4"},
			expected: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cards1, err := ParseCards(tt.player1)
			if err != nil {
				t.Fatalf("Failed to parse player1 cards: %v", err)
			}
			cards2, err := ParseCards(tt.player2)
			if err != nil {
				t.Fatalf("Failed to parse player2 cards: %v", err)
			}

			hand1, err := EvaluateHand(cards1)
			if err != nil {
				t.Fatalf("Failed to evaluate hand1: %v", err)
			}
			hand2, err := EvaluateHand(cards2)
			if err != nil {
				t.Fatalf("Failed to evaluate hand2: %v", err)
			}

			result := hand1.Compare(hand2)
			if result != tt.expected {
				t.Errorf("Expected %d, got %d.\nPlayer1: %s (Rank: %v, Detail: %v)\nPlayer2: %s (Rank: %v, Detail: %v)",
					tt.expected, result,
					hand1.Description, hand1.Rank, hand1.RankDetail,
					hand2.Description, hand2.Rank, hand2.RankDetail)
			}
		})
	}
}

// TestTwoPlayerScenarios tests realistic Texas Hold'em scenarios
func TestTwoPlayerScenarios(t *testing.T) {
	tests := []struct {
		name        string
		p1Hole      []string
		p2Hole      []string
		community   []string
		expected    int // 1 = player1 wins, -1 = player2 wins, 0 = tie
		description string
	}{
		{
			name:        "Aces beat Kings",
			p1Hole:      []string{"SA", "HA"},
			p2Hole:      []string{"SK", "HK"},
			community:   []string{"DQ", "C8", "S6", "H4", "D2"},
			expected:    1,
			description: "Player 1 has a pair of Aces, Player 2 has a pair of Kings",
		},
		{
			name:        "Higher two pair wins",
			p1Hole:      []string{"SA", "SK"},
			p2Hole:      []string{"SQ", "SJ"},
			community:   []string{"HA", "HK", "DQ", "C3", "D2"},
			expected:    1,
			description: "Player 1 has Aces and Kings, Player 2 has Queens and Kings",
		},
		{
			name:        "Set beats two pair",
			p1Hole:      []string{"SA", "HA"},
			p2Hole:      []string{"SK", "SQ"},
			community:   []string{"DA", "HK", "DQ", "C3", "D2"},
			expected:    1,
			description: "Player 1 has three Aces, Player 2 has two pair (Kings and Queens)",
		},
		{
			name:        "Flush beats straight",
			p1Hole:      []string{"S9", "S7"},
			p2Hole:      []string{"HT", "H9"},
			community:   []string{"SA", "SK", "SQ", "DJ", "C8"},
			expected:    1,
			description: "Player 1 has a flush, Player 2 has a straight",
		},
		{
			name:        "Both players have straight - tie",
			p1Hole:      []string{"ST", "H9"},
			p2Hole:      []string{"DT", "C9"},
			community:   []string{"SA", "HK", "DQ", "CJ", "S8"},
			expected:    0,
			description: "Both players have the same straight using the board",
		},
		{
			name:        "Kicker decides winner",
			p1Hole:      []string{"SA", "HQ"},
			p2Hole:      []string{"HA", "DJ"},
			community:   []string{"DA", "S9", "H7", "C5", "D3"},
			expected:    1,
			description: "Both have pair of Aces, Player 1 wins with Queen kicker",
		},
		{
			name:        "Full house over full house",
			p1Hole:      []string{"SA", "HA"},
			p2Hole:      []string{"SK", "HK"},
			community:   []string{"DA", "DK", "CK", "S9", "H7"},
			expected:    -1,
			description: "Player 2 has Kings full of Aces, Player 1 has Aces full of Kings",
		},
		{
			name:        "Quads in community - kicker matters",
			p1Hole:      []string{"SA", "HQ"},
			p2Hole:      []string{"HA", "DJ"},
			community:   []string{"SK", "DK", "CK", "HK", "S9"},
			expected:    0,
			description: "Both have four Kings with Ace kicker",
		},
		{
			name:        "Straight flush beats quads",
			p1Hole:      []string{"S9", "S8"},
			p2Hole:      []string{"HA", "DA"},
			community:   []string{"SQ", "SJ", "ST", "CA", "SA"},
			expected:    1,
			description: "Player 1 has straight flush, Player 2 has four Aces",
		},
		{
			name:        "Split pot - board plays",
			p1Hole:      []string{"S2", "H3"},
			p2Hole:      []string{"D4", "C5"},
			community:   []string{"SA", "HK", "DQ", "CJ", "ST"},
			expected:    0,
			description: "Board has the best hand (Ace-high straight), both players play the board",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p1HoleCards, _ := ParseCards(tt.p1Hole)
			p2HoleCards, _ := ParseCards(tt.p2Hole)
			communityCards, _ := ParseCards(tt.community)

			p1AllCards := append(p1HoleCards, communityCards...)
			p2AllCards := append(p2HoleCards, communityCards...)

			hand1, err := EvaluateHand(p1AllCards)
			if err != nil {
				t.Fatalf("Failed to evaluate hand1: %v", err)
			}
			hand2, err := EvaluateHand(p2AllCards)
			if err != nil {
				t.Fatalf("Failed to evaluate hand2: %v", err)
			}

			result := hand1.Compare(hand2)
			if result != tt.expected {
				t.Errorf("%s\nExpected %d, got %d.\nPlayer1: %s\nPlayer2: %s",
					tt.description, tt.expected, result,
					hand1.Description, hand2.Description)
			}
		})
	}
}
