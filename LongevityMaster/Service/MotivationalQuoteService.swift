//
//  MotivationalQuoteService.swift
//  LongevityMaster
//
//  Created by Banghua Zhao on 2025/07/17.
//  Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Dependencies
import Sharing

struct MotivationalQuote {
    let text: String
    let author: String
}

struct MotivationalQuoteService {
    @Shared(.appStorage("motivationalQuotesEnabled")) var motivationalQuotesEnabled = true
    @Shared(.appStorage("lastQuoteDismissedDate")) var lastQuoteDismissedDate: Date? = nil

    private var quotes: [MotivationalQuote] {
        [
            MotivationalQuote(
                text: String(localized: "The greatest wealth is health."),
                author: "Ralph Waldo Emerson"
            ),
            MotivationalQuote(
                text: String(localized: "Take care of your body. It's the only place you have to live."),
                author: "Jim Rohn"
            ),
            MotivationalQuote(
                text: String(localized: "Health is not valued till sickness comes."),
                author: "Thomas Fuller"
            ),
            MotivationalQuote(
                text: String(localized: "The first wealth is health."),
                author: "Ralph Waldo Emerson"
            ),
            MotivationalQuote(
                text: String(localized: "A healthy outside starts from the inside."),
                author: "Robert Urich"
            ),
            MotivationalQuote(
                text: String(localized: "Your health is an investment, not an expense."),
                author: String(localized: "Unknown")
            ),
            MotivationalQuote(
                text: String(localized: "The body achieves what the mind believes."),
                author: "Napoleon Hill"
            ),
            MotivationalQuote(
                text: String(localized: "Good health is not something we can buy. However, it can be an extremely valuable savings account."),
                author: "Anne Wilson Schaef"
            ),
            MotivationalQuote(
                text: String(localized: "Health is a relationship between you and your body."),
                author: "Terri Guillemets"
            ),
            MotivationalQuote(
                text: String(localized: "The only bad workout is the one that didn't happen."),
                author: String(localized: "Unknown")
            ),
            MotivationalQuote(
                text: String(localized: "Every day is a new beginning. Take a deep breath and start again."),
                author: String(localized: "Unknown")
            ),
            MotivationalQuote(
                text: String(localized: "Small progress is still progress."),
                author: String(localized: "Unknown")
            ),
            MotivationalQuote(
                text: String(localized: "Your future self is watching you right now through memories."),
                author: String(localized: "Unknown")
            ),
            MotivationalQuote(
                text: String(localized: "The only person you are destined to become is the person you decide to be."),
                author: "Ralph Waldo Emerson"
            ),
            MotivationalQuote(
                text: String(localized: "Consistency is the key to success."),
                author: String(localized: "Unknown")
            ),
            MotivationalQuote(
                text: String(localized: "Every expert was once a beginner."),
                author: "Robert T. Kiyosaki"
            ),
            MotivationalQuote(
                text: String(localized: "The difference between try and triumph is just a little umph!"),
                author: "Marvin Phillips"
            ),
            MotivationalQuote(
                text: String(localized: "Don't count the days, make the days count."),
                author: "Muhammad Ali"
            ),
            MotivationalQuote(
                text: String(localized: "The only way to do great work is to love what you do."),
                author: "Steve Jobs"
            ),
            MotivationalQuote(
                text: String(localized: "Success is not final, failure is not fatal: it is the courage to continue that counts."),
                author: "Winston Churchill"
            )
        ]
    }
    
    func getRandomQuote() -> MotivationalQuote {
        quotes.randomElement() ?? quotes[0]
    }
    
    func shouldShowQuote() -> Bool {
        if !motivationalQuotesEnabled {
            return false
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDismissed = lastQuoteDismissedDate {
            let lastDismissedDay = Calendar.current.startOfDay(for: lastDismissed)
            return lastDismissedDay < today
        }
        
        return true
    }
    
    func dismissQuoteForToday() {
        $lastQuoteDismissedDate.withLock { $0 = Date() }
    }
}

extension DependencyValues {
    var motivationalQuoteService: MotivationalQuoteService {
        get { self[MotivationalQuoteServiceKey.self] }
        set { self[MotivationalQuoteServiceKey.self] = newValue }
    }
}

private enum MotivationalQuoteServiceKey: DependencyKey {
    static let liveValue = MotivationalQuoteService()
} 
