package poker

import (
	"fmt"
	"sort"
)

// HandRank represents the ranking of a poker hand
type HandRank int

const (
	HighCard HandRank = iota
	OnePair
	TwoPair
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
	RoyalFlush
)

// String returns the name of the hand rank
func (hr HandRank) String() string {
	names := []string{
		"High Card",
		"One Pair",
		"Two Pair",
		"Three of a Kind",
		"Straight",
		"Flush",
		"Full House",
		"Four of a Kind",
		"Straight Flush",
		"Royal Flush",
	}
	if hr >= 0 && int(hr) < len(names) {
		return names[hr]
	}
	return "Unknown"
}

// Hand represents an evaluated poker hand
type Hand struct {
	Rank        HandRank
	RankDetail  []int // Detailed ranking for tie-breaking (e.g., [14, 13, 12] for A-K-Q high)
	Cards       []Card
	Description string
}

// Compare compares two hands. Returns 1 if h1 wins, -1 if h2 wins, 0 for tie
func (h1 *Hand) Compare(h2 *Hand) int {
	// Compare rank first
	if h1.Rank > h2.Rank {
		return 1
	}
	if h1.Rank < h2.Rank {
		return -1
	}

	// Same rank, compare rank details
	minLen := len(h1.RankDetail)
	if len(h2.RankDetail) < minLen {
		minLen = len(h2.RankDetail)
	}

	for i := 0; i < minLen; i++ {
		if h1.RankDetail[i] > h2.RankDetail[i] {
			return 1
		}
		if h1.RankDetail[i] < h2.RankDetail[i] {
			return -1
		}
	}

	return 0 // Tie
}

// EvaluateHand evaluates the best 5-card hand from the given cards
func EvaluateHand(cards []Card) (*Hand, error) {
	if len(cards) < 5 {
		return nil, fmt.Errorf("need at least 5 cards to evaluate a hand")
	}

	// Generate all 5-card combinations
	var bestHand *Hand
	combinations := generateCombinations(cards, 5)

	for _, combo := range combinations {
		hand := evaluateFiveCards(combo)
		if bestHand == nil || hand.Compare(bestHand) > 0 {
			bestHand = hand
		}
	}

	return bestHand, nil
}

// evaluateFiveCards evaluates exactly 5 cards
func evaluateFiveCards(cards []Card) *Hand {
	sorted := SortCards(cards)

	// Check for flush
	isFlush := true
	firstSuit := sorted[0].Suit
	for _, card := range sorted {
		if card.Suit != firstSuit {
			isFlush = false
			break
		}
	}

	// Check for straight
	isStraight, highCard := checkStraight(sorted)

	// Royal Flush: A-K-Q-J-T of same suit
	if isFlush && isStraight && highCard == 14 {
		return &Hand{
			Rank:        RoyalFlush,
			RankDetail:  []int{14},
			Cards:       sorted,
			Description: "Royal Flush",
		}
	}

	// Straight Flush
	if isFlush && isStraight {
		return &Hand{
			Rank:        StraightFlush,
			RankDetail:  []int{highCard},
			Cards:       sorted,
			Description: fmt.Sprintf("Straight Flush, %s high", rankToString(highCard)),
		}
	}

	// Count ranks
	rankCounts := make(map[int]int)
	for _, card := range sorted {
		rankCounts[card.Rank]++
	}

	// Convert to sorted counts
	type rankCount struct {
		rank  int
		count int
	}
	var counts []rankCount
	for rank, count := range rankCounts {
		counts = append(counts, rankCount{rank, count})
	}
	sort.Slice(counts, func(i, j int) bool {
		if counts[i].count != counts[j].count {
			return counts[i].count > counts[j].count
		}
		return counts[i].rank > counts[j].rank
	})

	// Four of a Kind
	if counts[0].count == 4 {
		rankDetail := []int{counts[0].rank, counts[1].rank}
		return &Hand{
			Rank:        FourOfAKind,
			RankDetail:  rankDetail,
			Cards:       sorted,
			Description: fmt.Sprintf("Four of a Kind, %ss", rankToString(counts[0].rank)),
		}
	}

	// Full House
	if counts[0].count == 3 && counts[1].count == 2 {
		rankDetail := []int{counts[0].rank, counts[1].rank}
		return &Hand{
			Rank:        FullHouse,
			RankDetail:  rankDetail,
			Cards:       sorted,
			Description: fmt.Sprintf("Full House, %ss over %ss", rankToString(counts[0].rank), rankToString(counts[1].rank)),
		}
	}

	// Flush
	if isFlush {
		rankDetail := make([]int, len(sorted))
		for i, card := range sorted {
			rankDetail[i] = card.Rank
		}
		return &Hand{
			Rank:        Flush,
			RankDetail:  rankDetail,
			Cards:       sorted,
			Description: fmt.Sprintf("Flush, %s high", rankToString(sorted[0].Rank)),
		}
	}

	// Straight
	if isStraight {
		return &Hand{
			Rank:        Straight,
			RankDetail:  []int{highCard},
			Cards:       sorted,
			Description: fmt.Sprintf("Straight, %s high", rankToString(highCard)),
		}
	}

	// Three of a Kind
	if counts[0].count == 3 {
		rankDetail := []int{counts[0].rank, counts[1].rank, counts[2].rank}
		return &Hand{
			Rank:        ThreeOfAKind,
			RankDetail:  rankDetail,
			Cards:       sorted,
			Description: fmt.Sprintf("Three of a Kind, %ss", rankToString(counts[0].rank)),
		}
	}

	// Two Pair
	if counts[0].count == 2 && counts[1].count == 2 {
		rankDetail := []int{counts[0].rank, counts[1].rank, counts[2].rank}
		return &Hand{
			Rank:        TwoPair,
			RankDetail:  rankDetail,
			Cards:       sorted,
			Description: fmt.Sprintf("Two Pair, %ss and %ss", rankToString(counts[0].rank), rankToString(counts[1].rank)),
		}
	}

	// One Pair
	if counts[0].count == 2 {
		rankDetail := []int{counts[0].rank, counts[1].rank, counts[2].rank, counts[3].rank}
		return &Hand{
			Rank:        OnePair,
			RankDetail:  rankDetail,
			Cards:       sorted,
			Description: fmt.Sprintf("One Pair, %ss", rankToString(counts[0].rank)),
		}
	}

	// High Card
	rankDetail := make([]int, len(sorted))
	for i, card := range sorted {
		rankDetail[i] = card.Rank
	}
	return &Hand{
		Rank:        HighCard,
		RankDetail:  rankDetail,
		Cards:       sorted,
		Description: fmt.Sprintf("High Card, %s", rankToString(sorted[0].Rank)),
	}
}

// checkStraight checks if the sorted cards form a straight
func checkStraight(sorted []Card) (bool, int) {
	// Regular straight check
	isStraight := true
	for i := 1; i < len(sorted); i++ {
		if sorted[i-1].Rank-sorted[i].Rank != 1 {
			isStraight = false
			break
		}
	}
	if isStraight {
		return true, sorted[0].Rank
	}

	// Check for A-2-3-4-5 (wheel)
	if sorted[0].Rank == 14 && sorted[1].Rank == 5 && sorted[2].Rank == 4 &&
		sorted[3].Rank == 3 && sorted[4].Rank == 2 {
		return true, 5 // High card is 5 in this case
	}

	return false, 0
}

// generateCombinations generates all k-combinations from cards
func generateCombinations(cards []Card, k int) [][]Card {
	var result [][]Card
	var current []Card

	var backtrack func(start int)
	backtrack = func(start int) {
		if len(current) == k {
			combo := make([]Card, k)
			copy(combo, current)
			result = append(result, combo)
			return
		}

		for i := start; i < len(cards); i++ {
			current = append(current, cards[i])
			backtrack(i + 1)
			current = current[:len(current)-1]
		}
	}

	backtrack(0)
	return result
}

// rankToString converts a rank number to string
func rankToString(rank int) string {
	switch rank {
	case 14:
		return "Ace"
	case 13:
		return "King"
	case 12:
		return "Queen"
	case 11:
		return "Jack"
	case 10:
		return "Ten"
	default:
		return fmt.Sprintf("%d", rank)
	}
}
