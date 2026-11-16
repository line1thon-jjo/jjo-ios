//
//  FeedbackRules+Templates.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated extension FeedbackRules {
    // 같은 종류가 최대 3개까지 나올 수 있어 종류마다 문구 3개를 둔다. 자리 표시 뒤에는 받침에 따라 바뀌는 조사를 붙이지 않는다
    static let templates: [TemplateKey: [Text]] = [
        .endRise: [
            Text(
                title: "문장 끝 내려 맺기",
                body: "‘{word}’에서 끝이 올라가 질문처럼 들렸어요. 마지막 글자를 살짝 내려 말해 보세요."
            ),
            Text(
                title: "끝 글자 낮게 맺기",
                body: "설명하는 문장인데 끝이 올라갔어요. ‘{word}’ 부분을 말할 때 목소리를 아래로 내려놓는다고 생각해 보세요."
            ),
            Text(
                title: "평서문처럼 끝내기",
                body: "여기서도 ‘{word}’에서 끝이 올라갔어요. 마침표를 떠올리며 끝 글자를 한 단계 낮춰 보세요."
            )
        ],
        .endStretch: [
            Text(
                title: "문장 끝 짧게 맺기",
                body: "{spot} 소리가 길게 끌렸어요. 마지막 글자를 짧게 끊고 마침표에서 숨을 쉬어 보세요."
            ),
            Text(
                title: "끝음 툭 끊기",
                body: "문장 끝을 길게 늘였어요. ‘{word}’까지 같은 박자로 말하고 바로 멈춰 보세요."
            ),
            Text(
                title: "마무리 깔끔하게 하기",
                body: "여기서도 ‘{char}’ 소리가 끌렸어요. 끝 글자를 다른 글자와 같은 길이로 말해 보세요."
            )
        ],
        .endFade: [
            Text(
                title: "끝까지 또렷하게",
                body: "‘{word}’에서 목소리가 작아져 끝이 잘 안 들렸어요. 마지막 글자까지 같은 크기로 말해 보세요."
            ),
            Text(
                title: "끝 단어 또렷하게 말하기",
                body: "문장 끝으로 갈수록 소리가 줄었어요. 끝 단어 ‘{word}’ 부분을 오히려 또렷하게 내 보세요."
            ),
            Text(
                title: "끝까지 같은 크기로 말하기",
                body: "여기서도 ‘{word}’에서 소리가 작아졌어요. 마지막 단어에 숨을 조금 남겨 두세요."
            )
        ],
        .midStretch: [
            Text(
                title: "중간에 늘이지 않기",
                body: "{spot} 소리가 길게 늘어졌어요. 다음 말을 고를 시간이 필요하면 늘이지 말고 잠깐 멈춰 보세요."
            ),
            Text(
                title: "늘이는 대신 잠깐 쉬기",
                body: "{spot} 소리를 끌면서 말이 이어졌어요. 글자마다 길이를 비슷하게 맞춰 보세요."
            ),
            Text(
                title: "글자 길이 고르게 맞추기",
                body: "여기서도 {spot} 소리가 길어졌어요. 늘이지 말고 다음 단어로 가볍게 넘어가 보세요."
            )
        ],
        .midPause: [
            Text(
                title: "문장 안에서 이어 말하기",
                body: "‘{word}’ 뒤에서 {sec}초 멈췄어요. 한 문장은 한 호흡에 이어서 말해 보세요."
            ),
            Text(
                title: "한 호흡에 읽기",
                body: "문장 중간에 멈추면 말이 끊겨 들려요. ‘{word}’부터 문장 끝까지 미리 소리 내어 이어 읽어 보세요."
            ),
            Text(
                title: "쉼 자리 옮기기",
                body: "‘{word}’ 뒤에서도 {sec}초 쉬었어요. 쉼은 쉼표나 마침표 자리로 옮겨 보세요."
            )
        ],
        .longPause: [
            Text(
                title: "쉼 길이 줄이기",
                body: "‘{word}’ 뒤에서 {sec}초 쉬었어요. 숨은 1초 안쪽으로 고르고 다음 문장을 시작해 보세요."
            ),
            Text(
                title: "쉼 짧게 하기",
                body: "문장 사이 쉼이 평소보다 길었어요. 다음 문장의 첫 단어를 미리 떠올려 두면 쉼이 짧아져요."
            ),
            Text(
                title: "흐름 이어 가기",
                body: "‘{word}’ 뒤에서도 {sec}초 쉬었어요. 한 박자 정도만 쉬고 이어 말해 보세요."
            )
        ],
        .noBreak: [
            Text(
                title: "마침표에서 한 번 쉬기",
                body: "‘{word}’에서 문장이 끝났는데 쉬지 않고 다음 말로 넘어갔어요. 마침표마다 숨 한 번씩 넣어 보세요."
            ),
            Text(
                title: "문장 구분해 말하기",
                body: "문장이 쉼 없이 붙어서 경계가 흐려졌어요. ‘{word}’ 뒤에서 반 박자 멈춰 보세요."
            ),
            Text(
                title: "마침표에서 숨 쉬기",
                body: "‘{word}’ 뒤에서도 바로 다음 문장으로 넘어갔어요. 문장 끝에서 짧게 숨을 쉬어 보세요."
            )
        ],
        .paceFast: [
            Text(
                title: "빠른 구절 천천히 말하기",
                body: "이 구절이 평소보다 빠르게 지나갔어요. 단어 사이를 반 박자씩 띄우며 또박또박 말해 보세요."
            ),
            Text(
                title: "빠른 구절 속도 늦추기",
                body: "이 구절도 평소보다 빨랐어요. 단어 하나하나를 또박또박 말해 보세요."
            ),
            Text(
                title: "한 박자 늦춰 읽기",
                body: "빨리 말하면 듣는 사람이 놓치기 쉬워요. 이 구절은 한 박자 늦춰 읽어 보세요."
            )
        ],
        .paceSlow: [
            Text(
                title: "느려진 구절 속도 맞추기",
                body: "이 구절에서 속도가 많이 느려졌어요. 앞 문장과 같은 속도로 이어서 읽어 보세요."
            ),
            Text(
                title: "느린 구절 당기기",
                body: "이 구절도 평소보다 느렸어요. 다른 구절처럼 자연스러운 속도로 읽어 보세요."
            ),
            Text(
                title: "속도 고르게 맞추기",
                body: "한 구절만 느려지면 흐름이 처져 들려요. 앞 구절의 속도를 이어 가 보세요."
            )
        ],
        .pause: [
            Text(
                title: "멈춘 자리 다듬기",
                body: "‘{word}’ 뒤에서 {sec}초 멈췄어요. 강조하려던 게 아니라면 쉼을 짧게 줄여 보세요."
            ),
            Text(
                title: "쉼 길이 줄이기",
                body: "‘{word}’ 뒤에서도 {sec}초 쉬었어요. 숨만 고르고 바로 다음 말로 넘어가 보세요."
            ),
            Text(
                title: "쉼 한 박자로 줄이기",
                body: "{sec}초 쉼은 길게 느껴질 수 있어요. 한 박자 정도로 줄여 보세요."
            )
        ]
    ]

    // 단어·쉼 길이를 채울 수 없거나 채운 뒤 상한을 넘을 때 쓰는 문구(자리 표시 없음)
    static let generic: [TemplateKey: [Text]] = [
        .endRise: [
            Text(
                title: "문장 끝 내려 맺기",
                body: "문장 끝에서 음높이가 올라갔어요. 마지막 글자를 살짝 내려 말해 보세요."
            ),
            Text(
                title: "끝 글자 낮게 맺기",
                body: "여기서도 문장 끝이 올라갔어요. 마침표를 떠올리며 끝 글자를 한 단계 낮춰 보세요."
            ),
            Text(
                title: "평서문처럼 끝내기",
                body: "끝이 올라가면 묻는 말처럼 들릴 수 있어요. 이 문장은 끝을 내리며 마무리해 보세요."
            )
        ],
        .endStretch: [
            Text(
                title: "문장 끝 짧게 맺기",
                body: "문장 끝을 길게 끌었어요. 마지막 글자를 짧고 분명하게 끝내 보세요."
            ),
            Text(
                title: "끝 글자 끌지 않기",
                body: "이 문장도 끝 글자를 늘였어요. 끝 글자를 다른 글자와 같은 길이로 말해 보세요."
            ),
            Text(
                title: "마무리 깔끔하게 하기",
                body: "문장 끝이 길어지면 말이 늘어져 들려요. 끝 글자에서 바로 멈춰 보세요."
            )
        ],
        .endFade: [
            Text(
                title: "끝까지 또렷하게",
                body: "문장 끝에서 목소리가 작아졌어요. 마지막 단어까지 같은 크기로 말해 보세요."
            ),
            Text(
                title: "끝 단어 또렷하게 말하기",
                body: "여기서도 끝으로 갈수록 목소리가 작아졌어요. 마지막 단어에 숨을 조금 남겨 두세요."
            ),
            Text(
                title: "끝까지 같은 크기로 말하기",
                body: "문장 끝이 작아지면 마지막 말이 잘 안 들려요. 끝 단어를 또박또박 말해 보세요."
            )
        ],
        .midStretch: [
            Text(
                title: "중간에 늘이지 않기",
                body: "문장 중간에서 말을 길게 늘였어요. 다음 단어를 미리 보고 고르게 이어 말해 보세요."
            ),
            Text(
                title: "글자 길이 고르게 맞추기",
                body: "이 부분에서도 중간 글자를 늘였어요. 글자마다 길이를 비슷하게 맞춰 보세요."
            ),
            Text(
                title: "늘이는 대신 잠깐 쉬기",
                body: "말을 늘이면 망설이는 듯 들릴 수 있어요. 생각할 틈이 필요하면 잠깐 멈춰 보세요."
            )
        ],
        .midPause: [
            Text(
                title: "문장 안에서 이어 말하기",
                body: "문장 중간에서 길게 쉬었어요. 한 문장은 한 호흡에 이어 말해 보세요."
            ),
            Text(
                title: "쉼 자리 옮기기",
                body: "이 문장도 중간에서 끊겼어요. 쉼은 쉼표나 마침표 자리로 옮겨 보세요."
            ),
            Text(
                title: "한 호흡에 읽기",
                body: "중간에 오래 쉬면 문장이 둘로 나뉘어 들려요. 미리 숨을 쉬고 한 번에 읽어 보세요."
            )
        ],
        .longPause: [
            Text(
                title: "쉼 길이 줄이기",
                body: "숨 고를 자리에서 평소보다 오래 쉬었어요. 쉼은 짧게 하고 바로 이어 가 보세요."
            ),
            Text(
                title: "쉼 짧게 하기",
                body: "이 자리에서도 오래 쉬었어요. 숨만 고르고 다음 문장으로 넘어가 보세요."
            ),
            Text(
                title: "흐름 이어 가기",
                body: "쉼이 길면 흐름이 끊겨 들려요. 한 박자 정도만 쉬고 이어 말해 보세요."
            )
        ],
        .noBreak: [
            Text(
                title: "마침표에서 한 번 쉬기",
                body: "문장이 끝났는데 쉬지 않고 이어 말했어요. 마침표 뒤에서 한 박자 쉬어 보세요."
            ),
            Text(
                title: "마침표에서 숨 쉬기",
                body: "이 문장도 끝나자마자 다음 문장으로 넘어갔어요. 문장 끝에서 짧게 숨을 쉬어 보세요."
            ),
            Text(
                title: "문장 구분해 말하기",
                body: "쉬지 않고 이어 말하면 문장 구분이 흐려져요. 문장 사이에 잠깐 멈춰 보세요."
            )
        ],
        .paceFast: templates[.paceFast] ?? [],
        .paceSlow: templates[.paceSlow] ?? [],
        .pause: [
            Text(
                title: "멈춘 자리 다듬기",
                body: "이 부분에서 오래 멈췄어요. 강조하려던 게 아니라면 쉼을 짧게 줄여 보세요."
            ),
            Text(
                title: "쉼 길이 줄이기",
                body: "여기서도 오래 쉬었어요. 숨만 고르고 바로 다음 말로 넘어가 보세요."
            ),
            Text(
                title: "쉼 한 박자로 줄이기",
                body: "긴 쉼은 흐름을 끊을 수 있어요. 한 박자 정도로 줄여 보세요."
            )
        ]
    ]

    // 조건이 맞을 때만 쓰라고 모델에만 주는 추가 예시
    static let conditionalExamples: [TemplateKey: [ConditionalExample]] = [
        .midStretch: [
            ConditionalExample(
                when: "늘인 글자가 조사일 때",
                body: "{spot} 소리를 끌면서 말이 이어졌어요. 조사는 앞 단어에 붙여서 가볍게 넘겨 보세요."
            )
        ]
    ]

    static let kindNames: [FeedbackKind: String] = [
        .endRise: "끝 올림",
        .endStretch: "끝 끌기",
        .endFade: "끝 흐림",
        .midStretch: "중간 늘임",
        .midPause: "중간 쉼",
        .longPause: "긴 쉼",
        .noBreak: "이어 말하기",
        .pace: "말 빠르기",
        .pause: "쉼"
    ]

    // 후보마다 주는 연습 방향. 문제와 다른 조언(예: 쉼 항목에 속도 이야기)을 막는다
    static let advices: [TemplateKey: String] = [
        .endRise: "문장 끝 음높이를 내려 맺기",
        .endStretch: "끝 글자를 짧고 분명하게 끝내기",
        .endFade: "마지막 단어까지 같은 크기로 말하기",
        .midStretch: "글자 길이를 고르게 맞추고, 생각할 틈은 늘임 대신 짧은 쉼으로 두기",
        .midPause: "문장 중간에서 끊지 말고 쉼표·마침표 자리에서 쉬기",
        .longPause: "숨만 고르고 쉼을 짧게 하기",
        .noBreak: "문장이 끝나면 한 박자 쉬기",
        .paceFast: "이 구절을 단어 사이를 띄우며 천천히 읽기",
        .paceSlow: "이 구절을 앞뒤 구절과 같은 속도로 읽기",
        .pause: "쉼을 한 박자 정도로 줄이기"
    ]

    static let kindMeanings: [FeedbackKind: String] = [
        .endRise: "문장 끝에서 음높이가 올라감",
        .endStretch: "문장 끝 글자를 길게 끎",
        .endFade: "문장 끝에서 목소리가 작아짐",
        .midStretch: "문장 중간에서 글자를 길게 늘임",
        .midPause: "문장 중간에서 길게 쉼",
        .longPause: "숨 고를 자리에서 평소보다 오래 쉼",
        .noBreak: "문장이 끝났는데 쉬지 않고 이어 말함",
        .pace: "이 구절을 본인 평균보다 빠르게(FAST) 또는 느리게(SLOW) 말함",
        .pause: "이 위치에서 눈에 띄게 오래 쉼"
    ]

    // 분석 수치로 알 수 없는 인상·감정·내용 평가라서 총평에 들어가면 그 줄을 규칙 문구로 바꾼다
    static let summaryBanned = ["차분", "자신감", "자신 있", "감정", "마음", "완벽", "멋진", "멋지", "훌륭", "내용"]
}
