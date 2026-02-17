import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
    stages: [
        { duration: '30s', target: 20 }, // Ramp up to 20 users
        { duration: '1m', target: 50 }, // Ramp up to 50 users
        { duration: '2m', target: 100 }, // Stay at 100 users for 2 minutes
        { duration: '1m', target: 50 }, // Ramp down to 50
        { duration: '30s', target: 0 }, // Ramp down to 0
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
        errors: ['rate<0.1'], // Error rate should be less than 10%
    },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';

export default function() {
    // Test 1: Health check
    let healthRes = http.get(`${BASE_URL}/health`);
    check(healthRes, {
        'health status is 200': (r) => r.status === 200,
    }) || errorRate.add(1);

    sleep(1);

    // Test 2: Evaluate hand
    const evaluatePayload = JSON.stringify({
        holeCards: ['HA', 'HK'],
        communityCards: ['HQ', 'HJ', 'HT', 'D2', 'C3']
    });

    const evaluateParams = {
        headers: { 'Content-Type': 'application/json' },
    };

    let evaluateRes = http.post(`${BASE_URL}/api/evaluate`, evaluatePayload, evaluateParams);
    check(evaluateRes, {
        'evaluate status is 200': (r) => r.status === 200,
        'evaluate returns success': (r) => JSON.parse(r.body).success === true,
        'evaluate returns hand rank': (r) => JSON.parse(r.body).handRank !== undefined,
    }) || errorRate.add(1);

    sleep(1);

    // Test 3: Compare hands
    const comparePayload = JSON.stringify({
        player1HoleCards: ['HA', 'HK'],
        player1CommunityCards: ['HQ', 'HJ', 'HT', 'D2', 'C3'],
        player2HoleCards: ['SA', 'SK'],
        player2CommunityCards: ['HQ', 'HJ', 'HT', 'D2', 'C3']
    });

    let compareRes = http.post(`${BASE_URL}/api/compare`, comparePayload, evaluateParams);
    check(compareRes, {
        'compare status is 200': (r) => r.status === 200,
        'compare returns success': (r) => JSON.parse(r.body).success === true,
        'compare returns winner': (r) => JSON.parse(r.body).winner !== undefined,
    }) || errorRate.add(1);

    sleep(1);

    // Test 4: Calculate probability (light simulation)
    const probabilityPayload = JSON.stringify({
        holeCards: ['HA', 'HK'],
        communityCards: ['HQ', 'HJ', 'HT'],
        numPlayers: 4,
        simulations: 100 // Keep it light for load testing
    });

    let probRes = http.post(`${BASE_URL}/api/probability`, probabilityPayload, evaluateParams);
    check(probRes, {
        'probability status is 200': (r) => r.status === 200,
        'probability returns success': (r) => JSON.parse(r.body).success === true,
        'probability returns win probability': (r) => JSON.parse(r.body).winProbability !== undefined,
    }) || errorRate.add(1);

    sleep(2);
}