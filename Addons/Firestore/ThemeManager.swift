// ThemeManager.swift
import Foundation

// MARK: - Менеджер Тем для Подій
struct ThemeManager {

    // Основний перелік тем для подій
    static let eventThemes: [EventTheme] = [
        EventTheme(name: "Вечірка", emoji: "🎉"),
        EventTheme(name: "Нічне життя", emoji: "🌃"),
        EventTheme(name: "Концерт", emoji: "🎤"),
        EventTheme(name: "Фестиваль", emoji: "🎡"),
        EventTheme(name: "День народження", emoji: "🎂"),
        EventTheme(name: "Караоке", emoji: "🎶"),
        EventTheme(name: "Танці", emoji: "💃"),
        EventTheme(name: "Костюмована вечірка", emoji: "🎭"),

        EventTheme(name: "Футбол", emoji: "⚽"),
        EventTheme(name: "Баскетбол", emoji: "🏀"),
        EventTheme(name: "Волейбол", emoji: "🏐"),
        EventTheme(name: "Пробіжка", emoji: "🏃‍♂️"),
        EventTheme(name: "Велопрогулянка", emoji: "🚴‍♀️"),
        EventTheme(name: "Йога", emoji: "🧘"),
        EventTheme(name: "Фітнес", emoji: "🏋️‍♀️"),
        EventTheme(name: "Похід", emoji: "🏕️"),
        EventTheme(name: "Плавання", emoji: "🏊"),
        EventTheme(name: "Зимові види спорту", emoji: "🏂"),

        EventTheme(name: "Лекція", emoji: "🗣️"),
        EventTheme(name: "Семінар", emoji: "📚"),
        EventTheme(name: "Майстер-клас", emoji: "🎨"),
        EventTheme(name: "Тренінг", emoji: "🧠"),
        EventTheme(name: "Конференція", emoji: "🤝"),
        EventTheme(name: "Мовні курси", emoji: "🌐"),
        EventTheme(name: "Читацький клуб", emoji: "📖"),

        EventTheme(name: "Виставка", emoji: "🖼️"),
        EventTheme(name: "Театр", emoji: "🎭"),
        EventTheme(name: "Кіно", emoji: "🎬"),
        EventTheme(name: "Музей", emoji: "🏛️"),
        EventTheme(name: "Фотографія", emoji: "📸"),
        EventTheme(name: "Музичний вечір", emoji: "🎻"),

        EventTheme(name: "Гастро-вечір", emoji: "🍔"),
        EventTheme(name: "Дегустація вин", emoji: "🍷"),
        EventTheme(name: "Кулінарний майстер-клас", emoji: "🧑‍🍳"),
        EventTheme(name: "Кава-брейк", emoji: "☕"),
        EventTheme(name: "Пікнік", emoji: "🧺"),

        EventTheme(name: "Настільні ігри", emoji: "🎲"),
        EventTheme(name: "Відеоігри", emoji: "🎮"),
        EventTheme(name: "Рукоділля", emoji: "🧵"),
        EventTheme(name: "Садівництво", emoji: "🌱"),
        EventTheme(name: "Волонтерство", emoji: "🙌"),
        EventTheme(name: "Нетворкінг", emoji: "💼"),
        
        EventTheme(name: "Екскурсія містом", emoji: "🏙️"),
        EventTheme(name: "Подорож", emoji: "✈️"),
        EventTheme(name: "Квест", emoji: "🗺️"),

        EventTheme(name: "Благодійний захід", emoji: "💖"),
        EventTheme(name: "Зустріч спільноти", emoji: "👨‍👩‍👧‍👦"),
        EventTheme(name: "Ярмарок", emoji: "🛍️")
    ]
}

// MARK: - Модель Теми Події
struct EventTheme: Hashable, Equatable {
    let id = UUID()
    let name: String
    let emoji: String?

    // Обчислює хеш-значення для екземпляра.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Порівнює два екземпляри EventTheme на рівність.
    static func == (lhs: EventTheme, rhs: EventTheme) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Повертає назву теми з емодзі (якщо є) для відображення.
    var displayName: String {
        if let emoji = emoji {
            return "\(emoji) \(name)"
        }
        return name
    }
}
