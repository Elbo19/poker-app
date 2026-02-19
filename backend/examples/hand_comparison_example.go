package main

import (
	"encoding/json"
	"fmt"
	"poker-app/internal/poker"
	"strings"
)

// Example demonstrates full hand comparison functionality
func main() {
	fmt.Println("=== Texas Hold'em Hand Comparison Examples ===")
	fmt.Println()

	// Example 1: Pair of Aces vs Pair of Kings
	example1()

	// Example 2: Full House vs Flush
	example2()

	// Example 3: Tie with same hand
	example3()

	// Example 4: Kicker decides winner
	example4()
}

func example1() {
	fmt.Println(strings.Repeat("-", 50))
	fmt.Println("Example 1: Pair of Aces vs Pair of Kings")
	p1Hole := []string{"SA", "HA"}
	p2Hole := []string{"SK", "HK"}
	community := []string{"DQ", "C8", "S6", "H4", "D2"}
	compareHands(p1Hole, p2Hole, community)
	fmt.Println()
}

func example2() {
	fmt.Println(strings.Repeat("-", 50))
	fmt.Println("Example 2: Full House vs Flush")
	p1Hole := []string{"SA", "HA"}
	p2Hole := []string{"S9", "S7"}
	community := []string{"DA", "SK", "SQ", "DJ", "C8"}
	compareHands(p1Hole, p2Hole, community)
	fmt.Println()
}

func example3() {
	fmt.Println(strings.Repeat("-", 50))
	fmt.Println("Example 3: Tie - Both players use the board")
	p1Hole := []string{"S2", "H3"}
	p2Hole := []string{"D4", "C5"}
	community := []string{"SA", "HK", "DQ", "CJ", "ST"}
	compareHands(p1Hole, p2Hole, community)
	fmt.Println()
}

func example4() {
	fmt.Println(strings.Repeat("-", 50))
	fmt.Println("Example 4: Same pair - Kicker decides")
	p1Hole := []string{"SA", "HQ"}
	p2Hole := []string{"HA", "DJ"}
	community := []string{"DA", "S9", "H7", "C5", "D3"}
	compareHands(p1Hole, p2Hole, community)
	fmt.Println()
}

func compareHands(p1Hole, p2Hole, community []string) {
	// Parse cards
	p1HoleCards, _ := poker.ParseCards(p1Hole)
	p2HoleCards, _ := poker.ParseCards(p2Hole)
	communityCards, _ := poker.ParseCards(community)

	// Combine hole cards with community cards
	p1AllCards := append(p1HoleCards, communityCards...)
	p2AllCards := append(p2HoleCards, communityCards...)

	// Evaluate best hands
	hand1, _ := poker.EvaluateHand(p1AllCards)
	hand2, _ := poker.EvaluateHand(p2AllCards)

	// Display cards
	fmt.Printf("Community: %v\n", community)
	fmt.Printf("Player 1 Hole: %v\n", p1Hole)
	fmt.Printf("Player 2 Hole: %v\n", p2Hole)
	fmt.Println()

	// Display hands
	fmt.Printf("Player 1: %s\n", hand1.Description)
	fmt.Printf("  Cards: ")
	for _, card := range hand1.Cards {
		fmt.Printf("%s ", card.String())
	}
	fmt.Println()

	fmt.Printf("Player 2: %s\n", hand2.Description)
	fmt.Printf("  Cards: ")
	for _, card := range hand2.Cards {
		fmt.Printf("%s ", card.String())
	}
	fmt.Println()

	// Compare and determine winner
	result := hand1.Compare(hand2)
	var winner string
	switch result {
	case 1:
		winner = "Player 1 wins!"
	case -1:
		winner = "Player 2 wins!"
	case 0:
		winner = "Tie!"
	}

	fmt.Printf("\nResult: %s\n", winner)

	// Show detailed ranking for debugging
	detailJSON, _ := json.MarshalIndent(map[string]interface{}{
		"player1": map[string]interface{}{
			"rank":       hand1.Rank.String(),
			"rankDetail": hand1.RankDetail,
		},
		"player2": map[string]interface{}{
			"rank":       hand2.Rank.String(),
			"rankDetail": hand2.RankDetail,
		},
	}, "", "  ")
	fmt.Printf("\nDetailed Ranking:\n%s\n", string(detailJSON))
}
