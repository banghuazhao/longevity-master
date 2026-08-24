import SwiftUI
import Dependencies

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    var title: LocalizedStringKey? = nil
    var categoryOrder: [Category] = Category.allCases
    
    @Dependency(\.themeManager) var themeManager
    
    enum Category: String, CaseIterable, Identifiable {
        case smileys = "Smileys"
        case animals = "Animals"
        case food = "Food"
        case activities = "Activities"
        case objects = "Objects"
        var id: String { rawValue }

        /// `rawValue` keys the emoji table, so the label the picker shows is separate.
        var title: LocalizedStringKey {
            switch self {
            case .smileys: return "Smileys"
            case .animals: return "Animals"
            case .food: return "Food"
            case .activities: return "Activities"
            case .objects: return "Objects"
            }
        }
    }
    
    static let emojiByCategory: [Category: [String]] = [
        .smileys: [
            "😀","😃","😄","😁","😆","😅","😂","🤣","😊","😇","🙂","🙃","😉","😍","🥰","😘","😗","😙","😚","😋","😜","😝","😛","🤑","🤗","🤩","🤔","🤨","😐","😑","😶","🙄","😏","😒","😞","😔","😟","😕","🙁","☹️","😣","😖","😫","😩","🥺","😢","😭","😤","😠","😡","🤬","🤯","😳","🥵","🥶","😱","😨","😰","😥","😓","😬","😯","😦","😧","😮","😲","🥱","😴","🤤","😪","😵","🤐","🥴","🤢","🤮","🤧","😷","🤒","🤕","🤠","😎","🤓","🧐","🥸","🥳","🤡","🫠"
        ],
        .animals: [
            "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🙈","🙉","🙊","🐒","🐔","🐧","🐦","🐤","🐣","🐥","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐞","🐜","🦟","🦗","🕷️","🦂","🐢","🐍","🦎","🦖","🦕","🐙","🦑","🦐","🦞","🦀","🐡","🐠","🐟","🐬","🐳","🐋","🦈","🐊","🦓","🦍","🦧","🐘","🦛","🦏","🐪","🐫","🦒","🦘","🦬","🐃","🐂","🐄","🐎","🐖","🐏","🐑","🦙","🐐","🦌","🐕","🐩","🦮","🐕‍🦺","🐈","🐈‍⬛","🦝","🦨","🦡","🦫","🦦","🦥","🐁","🐀","🐿️","🦔"
        ],
        .food: [
            "🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥬","🥒","🌶️","🫑","🌽","🥕","🫒","🧄","🧅","🥔","🍠","🥐","🥯","🍞","🥖","🥨","🥞","🧇","🥓","🥩","🍗","🍖","🦴","🌭","🍔","🍟","🍕","🥪","🥙","🧆","🌮","🌯","🫔","🥗","🥘","🫕","🥫","🍝","🍜","🍲","🍛","🍣","🍱","🥟","🦪","🍤","🍙","🍚","🍘","🍥","🥠","🥮","🍢","🍡","🍧","🍨","🍦","🥧","🧁","🍰","🎂","🍮","🍭","🍬","🍫","🍿","🍩","🍪","🥛","🍼","🫗","☕️","🍵","🧃","🥤","🧋","🍶","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🧉","🍾","🧊"
        ],
        .activities: [
            "⚽️","🏀","🏈","⚾️","🥎","🎾","🏐","🏉","🥏","🎱","🏓","🏸","🥅","🏒","🏑","🏏","🥍","🏹","🎣","🤿","🥊","🥋","🎽","🛹","🛼","🛷","⛸️","🥌","🛶","⛵️","🚣","🧗","🏇","🏂","⛷️","🏌️","🏄","🚴","🚵","🤸","🤾","⛹️","🤺","🤼","🤽","🏆","🥇","🥈","🥉","🏅","🎖️","🏵️","🎗️","🎫","🎟️","🎪","🤹","🎭","🩰","🎨","🎬","🎤","🎧","🎼","🎹","🥁","🎷","🎺","🎸","🎻","🎲","♟️","🎯","🎳","🎮","🎰","🧩","🧸","🪅","🪩","🪆"
        ],
        .objects: [
            "💡","🔦","🏮","🪔","📔","📕","📖","📗","📘","📙","📚","📓","📒","📃","📜","📄","📰","🗞️","📑","🔖","🏷️","💰","🪙","💴","💵","💶","💷","💸","💳","🧾","💹","💱","💲","✉️","📧","📨","📩","📤","📥","📦","📫","📪","📬","📭","📮","🗳️","✏️","✒️","🖋️","🖊️","🖌️","🖍️","📝","💼","📁","📂","🗂️","📅","📆","🗒️","🗓️","📇","📈","📉","📊","📋","📌","📍","📎","🖇️","📏","📐","✂️","🗃️","🗄️","🗑️","🔒","🔓","🔏","🔐","🔑","🗝️","🔨","🪓","⛏️","⚒️","🛠️","🗡️","⚔️","🔫","🏹","🛡️","🪚","🔧","🪛","🔩","⚙️","🗜️","⚖️","🦯","🔗","⛓️","🪝","🧰","🧲","🪜","⚗️","🧪","🧫","🧬","🔬","🔭","📡","💉","🩸","💊","🩹","🩺","🚪","🛗","🪞","🪟","🛏️","🛋️","🪑","🚽","🚿","🛁","🪠","🧴","🧷","🧹","🧺","🧻","🪣","🧼","🫧","🪥","🧽","🧯","🛒"
        ]
    ]
    
    @State private var selectedCategory: Category = .smileys
    
    var body: some View {
        VStack(spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.headline)
            }
            Picker("Category", selection: $selectedCategory) {
                ForEach(categoryOrder) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            let columns = [GridItem(.adaptive(minimum: 44))]
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Self.emojiByCategory[selectedCategory] ?? [], id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                        }) {
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 44, height: 44)
                                .background(selectedEmoji == emoji ? themeManager.current.primaryColor.opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            selectedCategory = categoryOrder.first ?? .smileys
        }
    }
} 
