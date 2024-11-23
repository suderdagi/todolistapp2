import SwiftUI
import UserNotifications

// Yapılacaklar Modeli
struct YapilacakItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var details: String
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool = false
    var priority: Oncelik
    var kategori: Kategori
    var isFavorite: Bool = false
}

// Öncelik Seviyeleri
enum Oncelik: String, CaseIterable, Identifiable, Codable {
    case yuksek = "Yüksek"
    case orta = "Orta"
    case dusuk = "Düşük"
    var id: String { self.rawValue }
}

// Kategoriler
enum Kategori: String, CaseIterable, Identifiable, Codable {
    case isKategori = "İş"
    case ev = "Ev"
    case ogrenme = "Öğrenme"
    case eglence = "Eğlence"
    var id: String { self.rawValue }
}

// ViewModel
class ViewModel: ObservableObject {
    @Published var yapilacaklarListesi: [YapilacakItem] = []
    
    init() {
        loadTasks()
    }
    
    func addYapilacakItem(title: String, details: String, startDate: Date, endDate: Date, priority: Oncelik, kategori: Kategori) {
        let newItem = YapilacakItem(title: title, details: details, startDate: startDate, endDate: endDate, priority: priority, kategori: kategori)
        yapilacaklarListesi.append(newItem)
        yapilacaklarListesi.sort { $0.startDate < $1.startDate }
        saveTasks()
        sendNotification(for: newItem)
    }
    
    func toggleCompletion(for item: YapilacakItem) {
        if let index = yapilacaklarListesi.firstIndex(where: { $0.id == item.id }) {
            yapilacaklarListesi[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    func toggleFavorite(for item: YapilacakItem) {
        if let index = yapilacaklarListesi.firstIndex(where: { $0.id == item.id }) {
            yapilacaklarListesi[index].isFavorite.toggle()
            saveTasks()
        }
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(yapilacaklarListesi) {
            UserDefaults.standard.set(encoded, forKey: "yapilacaklarListesi")
        }
    }
    
    private func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "yapilacaklarListesi"),
           let decodedTasks = try? JSONDecoder().decode([YapilacakItem].self, from: savedData) {
            yapilacaklarListesi = decodedTasks
        }
    }
    
    private func sendNotification(for item: YapilacakItem) {
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.details
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.startDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim hatası: \(error.localizedDescription)")
            }
        }
    }
}

// ContentView
struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @State private var newTitle: String = ""
    @State private var newDetails: String = ""
    @State private var selectedStartDate: Date = Date()
    @State private var selectedEndDate: Date = Date()
    @State private var selectedPriority: Oncelik = .orta
    @State private var selectedKategori: Kategori = .isKategori
    @State private var showThemeSettings: Bool = false
    @AppStorage("darkMode") var darkMode: Bool = false
    @AppStorage("selectedTheme") var selectedTheme: String = "light" // Varsayılan tema "light"
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Yapılacaklar Listesi")
                    .font(.custom("Snell Roundhand", size: 36))
                    .foregroundColor(.pink)
                    .bold()
                    .padding()
                
                ScrollView {
                    ForEach(viewModel.yapilacaklarListesi) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .strikethrough(item.isCompleted, color: .black)
                                    .font(.headline)
                                
                                Text(item.details)
                                    .font(.subheadline)
                                
                                Text("Tarih: \(item.startDate.formatted())")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: { viewModel.toggleFavorite(for: item) }) {
                                Image(systemName: item.isFavorite ? "star.fill" : "star")
                                    .foregroundColor(item.isFavorite ? .yellow : .gray)
                                    .scaleEffect(item.isFavorite ? 1.2 : 1.0)
                                    .animation(.spring(), value: item.isFavorite)
                            }
                            Button(action: { viewModel.toggleCompletion(for: item) }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .gray)
                            }
                        }
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                
                VStack(spacing: 10) {
                    TextField("Başlık", text: $newTitle)
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    TextField("Detaylar", text: $newDetails)
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    DatePicker("Başlangıç", selection: $selectedStartDate, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal)
                    
                    DatePicker("Bitiş", selection: $selectedEndDate, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal)
                    
                    Picker("Öncelik", selection: $selectedPriority) {
                        ForEach(Oncelik.allCases) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    Picker("Kategori", selection: $selectedKategori) {
                        ForEach(Kategori.allCases) { kategori in
                            Text(kategori.rawValue).tag(kategori)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    Button(action: { addYapilacakItem() }) {
                        Text("Ekle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                Button(action: { showThemeSettings = true }) {
                    Text("Tema Ayarları")
                        .foregroundColor(.pink)
                        .padding()
                        .background(Color.pink.opacity(0.2))
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showThemeSettings) {
                    VStack {
                        Toggle("Karanlık Mod", isOn: $darkMode)
                            .padding()
                        
                        Picker("Tema Seç", selection: $selectedTheme) {
                            Text("Aydınlık Tema").tag("light")
                            Text("Çiçekli Tema").tag("flower")
                            Text("Karanlık Tema").tag("dark")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        Text("Tema ayarlarını buradan değiştirebilirsiniz!")
                            .font(.headline)
                            .padding()
                    }
                    .padding()
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .background(
                backgroundImage(for: selectedTheme)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            )
            .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
    
    private func addYapilacakItem() {
        viewModel.addYapilacakItem(title: newTitle, details: newDetails, startDate: selectedStartDate, endDate: selectedEndDate, priority: selectedPriority, kategori: selectedKategori)
        newTitle = ""
        newDetails = ""
    }
    
    private func backgroundImage(for theme: String) -> Image {
        switch theme {
        case "flower":
            return Image("flower_background") // flower_background image
        case "dark":
            return Image("dark_background") // dark_background image (Assets'den alınacak)
        default:
            return Image("light_background") // light_background image (Assets'den alınacak)
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
