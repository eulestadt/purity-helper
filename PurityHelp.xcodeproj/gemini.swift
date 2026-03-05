import SwiftUI

// MARK: - Main App Entry Placeholder
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            Text("Urge Moment")
                .tabItem {
                    Label("Urge", systemImage: "water.waves")
                }
            Text("Reflect")
                .tabItem {
                    Label("Reflect", systemImage: "cross.fill")
                }
            Text("Stories")
                .tabItem {
                    Label("Stories", systemImage: "book.fill")
                }
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        // Tint color for the selected tab
        .tint(.blue)
    }
}

// MARK: - Home Dashboard
struct HomeView: View {
    var body: some View {
        ZStack {
            // Background Gradient: Soft, calm colors for the Liquid Glass base
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.85, green: 0.9, blue: 0.95), // Soft Blue
                    Color(red: 0.95, green: 0.9, blue: 0.85), // Warm Neutral
                    Color(red: 0.9, green: 0.95, blue: 0.9)   // Gentle Green
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Header
                    HStack {
                        Spacer()
                        Text("Purity Help")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // Anchor Scripture
                    VStack(spacing: 6) {
                        Text("\"Blessed are the pure in heart,\nfor they shall see God.\"")
                            .font(.system(size: 19, weight: .medium, design: .serif))
                            .multilineTextAlignment(.center)
                        Text("(Mt 5:8)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Main Tree Card (Seedling to Tree Viz)
                    TreeProgressCard()

                    // Action Buttons
                    VStack(spacing: 16) {
                        // Urge Button
                        Button(action: {
                            // Action to trigger Urge Moment flow
                        }) {
                            HStack {
                                Image(systemName: "water.waves")
                                    .font(.title2)
                                Text("I'm having an urge.")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            // Liquid Glass styling
                            .background(Color.blue.opacity(0.15).background(.ultraThinMaterial))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                            .foregroundColor(.blue)
                        }

                        // Daily Examen Button
                        Button(action: {
                            // Action to trigger Examen flow
                        }) {
                            HStack {
                                Image(systemName: "cross.fill")
                                    .font(.title3)
                                Text("Daily Examen")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.brown.opacity(0.1).background(.ultraThinMaterial))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                            .foregroundColor(.brown)
                        }
                    }
                    .padding(.horizontal)

                    // Scripture of the Day Card
                    InfoCard(
                        title: "Scripture of the Day",
                        subtitle: "Create in me a clean heart, O God... (Ps 51:10)",
                        icon: nil,
                        isOptional: false
                    )

                    // Story of the Day Card
                    InfoCard(
                        title: "Story of the Day",
                        subtitle: "Story of Hope: Finding Freedom after 14 Years\nSummary on finding freedom...",
                        icon: "sun.max.fill", // Placeholder for actual story thumbnail
                        isOptional: true
                    )

                }
                .padding(.top, 10)
            }
        }
    }
}

// MARK: - Components

struct TreeProgressCard: View {
    var body: some View {
        ZStack {
            // Base Card Material
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Nature Background Simulation (The green rolling hills)
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.25), Color.clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

            HStack(alignment: .bottom) {
                // Left Side: Tree Illustration
                VStack(alignment: .leading) {
                    Spacer()
                    // SF Symbol placeholder for the custom tree illustration
                    Image(systemName: "tree.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.2)) // Sapling green
                        .padding(.bottom, 8)
                        .padding(.leading, 10)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Purity Tree")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Young Tree (45 days)")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()

                // Right Side: Metrics Widgets
                VStack(spacing: 12) {
                    
                    // Days of Purity Badge
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom)
                            )
                            .font(.title)
                            .shadow(color: .orange.opacity(0.5), radius: 5)
                        
                        Text("45")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        
                        Text("DAYS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(1.5)
                        
                        Text("Days of Purity")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .frame(width: 105)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    
                    // Hours Reclaimed Badge
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        Text("12")
                            .font(.title2)
                            .fontWeight(.bold)
                            .design(.rounded)
                        
                        Text("HOURS\nRECLAIMED")
                            .font(.system(size: 9, weight: .bold))
                            .multilineTextAlignment(.center)
                            .tracking(0.5)
                    }
                    .padding(.vertical, 10)
                    .frame(width: 105)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
        .frame(height: 280)
        .padding(.horizontal)
    }
}

struct InfoCard: View {
    var title: String
    var subtitle: String
    var icon: String?
    var isOptional: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = icon {
                // Placeholder for an actual image thumbnail
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.orange)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isOptional {
                        Text("(Optional)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}