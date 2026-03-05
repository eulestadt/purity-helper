Here is the complete, technical product specification for the **"Vigil" Prayer Module**. It is written explicitly for an iOS engineer, translating the theological and clinical concepts into precise SwiftUI, SwiftData, and architectural requirements.

You can copy and paste this directly into Jira, Notion, or your project management tool.

---

# **Feature Specification: The "Vigil" Prayer Module**

## **1. Engineer Overview**

**Context:** Purity Help is a recovery app for pornography addiction. When a user experiences an "urge" (a spike in dopamine/craving), their prefrontal cortex goes offline.
**The Goal:** The "Vigil" module is a somatic, highly interactive prayer intervention. It forces physical engagement (gestures, haptics) to physically ground the user, while feeding them time-contextual, tradition-specific prayers (e.g., Book of Common Prayer, Orthodox liturgies) to disrupt the craving in under 2 minutes.
**Display Constraints:** Must be presented as a modal/full-screen takeover (`.fullScreenCover`) that hides all standard app navigation to remove distractions. Dark mode, "Glassmorphism" UI.

---

## **2. Data Layer & Architecture Updates**

### **A. SwiftData Schema Updates**

Extend the existing `JournalEntry` model to log when a user successfully completes a Vigil prayer.

```swift
// Enum update for EntryType
enum EntryType: String, Codable {
    case examen, urgeLog, reset, boundary
    case vigilPrayer // NEW
}

// Ensure JournalEntry can store Vigil-specific metadata
@Model
final class JournalEntry {
    var date: Date
    var type: EntryType 
    var text: String? 
    var tags: [String]? // e.g., ["Porneia/Lust", "Morning"]
    var durationCompleted: TimeInterval // To track if they did the 2-min or 10-min flow
    var outcome: String // e.g., "Intercepted", "Escalated"
}

```

### **B. JSON Data Structure (`liturgies.json`)**

Use the `PurityHelp/Resources/Prayers/liturgies.json`. The `VigilService` will parse this to serve the correct prayer based on time and user settings.


```

---

## **3. Service Layer Requirements (`VigilService.swift`)**

Create a `@Observable` class to manage the state and logic of the Vigil flow.

**Key Responsibilities:**

1. **Time Detection:** Calculate the current device time.
* *Morning:* 5:00 AM - 11:59 AM
* *Night:* 8:00 PM - 4:59 AM
* *Day:* 12:00 PM - 7:59 PM


2. **Tradition Filtering:** Read the user's tradition from `AppStorage` (Catholic, Orthodox, Protestant, Ecumenical) to filter the `liturgies.json` array.
3. **Content Selection Engine:**
* When the user selects their "Trigger" (Phase 2), query either `liturgies.json` OR the `ScriptureService` (from the "Hide in your heart" memorization feature).
* Randomize slightly if multiple valid prayers match the criteria to prevent staleness.



---

## **4. UI/UX Flow Details (SwiftUI)**

The core feature is housed in `VigilContainerView.swift`, which manages the transition between phases using `withAnimation`. Background should be a dark gradient with `.ultraThinMaterial` overlays.

### **Phase 1: The Threshold (`ThresholdView`)**

* **UI:** Minimalist screen. Text: *"Enter the Sanctuary. Press and hold."* A glowing thumbprint or flame icon in the center.
* **Interaction:** Require a `LongPressGesture` with `minimumDuration: 5.0`.
* **Haptics:** As the user presses, trigger a continuous haptic pattern. In iOS 17+, use `.sensoryFeedback(.impact, trigger: isPressing)`. On completion, play `.sensoryFeedback(.success)`.
* **Logic:** Once 5 seconds completes, auto-advance to Phase 2.

### **Phase 2: Naming the Trigger (`LogismoiSelectorView`)**

* **UI:** A 2x2 grid of soft, glass-morphism buttons.
* **Data Labels:** Lust (Porneia), Boredom (Acedia), Anger (Ogre), Loneliness (Lype).
* **Logic:** User taps one. Save this string to pass to the `JournalEntry` tags later. Auto-advance to Phase 3.

### **Phase 3: The Counter-Prayer (`AntirrhetikosView`)**

* **UI:** The selected prayer (from `VigilService`) is displayed on screen, but it is initially obscured (e.g., opacity set to 0.1, or overlaid with a blur mask).
* **Interaction (The "Reveal"):** The user must drag their finger across the screen to "wipe away the fog" and reveal the text, or tap rhythmically (like a prayer rope) to reveal it line-by-line.
* *Engineer Note:* You can achieve the wipe effect using a `DragGesture` that updates the position of a `mask` shape, or simply require the user to hold a "Reveal" button while reading.


* **Action:** A "Next" button fades in after 5 seconds to prevent rushing.

### **Phase 4: The Release (`ReleaseView`)**

* **UI:** Text: *"Pass by without entering."* An abstract graphic (like a swirling mist or heavy stone) sits in the middle of the screen.
* **Interaction:** A vertical `DragGesture`. The user must physically swipe the object UP and OFF the top of the screen.
* **Completion:** * Trigger an audio file using `AVAudioPlayer` (Asset: `monastery_bell.mp3`).
* Save the `JournalEntry` to SwiftData.
* If this was triggered from an active `UrgeLog`, mark the `UrgeLog` as resolved without resetting the user's streak.
* Show "Exit" button or "Stay Longer (10 mins)" button.



---

## **5. The 10-Minute Extended Sanctuary**

If the user clicks "Stay Longer," they enter a `TabView` with two options.

### **Option A: Litany of the Ascetics (`LitanyView`)**

* **UI:** A Call-and-Response interface.
* **Logic:**
* Fetch a litany from `liturgies.json` (where `type == "call_and_response"`).
* Display `call[currentIndex]` (e.g., *"From all blindness of heart..."*).
* Provide a large, tappable button displaying the `response` string (e.g., *"Good Lord, deliver us."*).
* When the user taps the button, trigger light haptic feedback (`.sensoryFeedback(.selection)`), increment `currentIndex`, and animate the text scrolling upward (`ScrollViewReader` with `.scrollTo()`).



### **Option B: Audio Watchfulness (`AudioSanctuaryView`)**

* **UI:** A standard, elegant audio player (Play, Pause, Progress Bar).
* **Logic:** Integrate standard `AVPlayer`. Load local audio file (`watchfulness_guided.mp3`). Prevent the screen from sleeping (`UIApplication.shared.isIdleTimerDisabled = true` while playing).

---

## **6. Integration Points in Existing App**

1. **Home Dashboard (`HomeView.swift`):**
* Add a floating action button (FAB) in the bottom right corner (a subtle flame icon). Action: `.fullScreenCover(isPresented: $showVigil) { VigilContainerView() }`.


2. **Urge Moment (`UrgeMomentView.swift`):**
* Add "Pray the Vigil" to the top of the "What will you do instead?" (Replace Activity) list. Action: Triggers the same `fullScreenCover`.


3. **If-Then Plans (`IfThenPlan.swift`):**
* Add "Pray the Vigil" as an available `Action` enum for the user's pre-made plans.



---

Updated Section 7: Assets Required from Design/Audio Team
Audio (Release Phase): Glocke.mp3 (Source: Wikimedia Commons.).
Audio (Sanctuary Phase): watchfulness_guided.mp3 (7-minute spoken meditation, to be generated via external TTS/Voice AI).
Icons (SF Symbols preferred): flame.fill (Vigil Icon), touchid or hand.point.up.braille.fill (Threshold holding icon).
JSON: liturgies.json populated with the specified BCP, Orthodox, and Catholic prayers.
Addendum A: Required Resource Citations & Licensing
To ensure the app respects intellectual property and proper theological attribution, the following citations must be included in the app's "About" or "Credits" section.

1. Liturgical Texts:
The Book of Common Prayer (1979 & 1662): The Collect for Purity, The Collect for Aid against Perils ("Lighten our darkness"), The Ash Wednesday Collect, and excerpts from The Great Litany. (Note: The 1979 BCP of the Episcopal Church is in the public domain, but standard attribution is best practice: "Liturgical texts adapted from The Book of Common Prayer.")
Orthodox Compline: The "Visit this place, O Lord" prayer is a traditional evening prayer found in Eastern Orthodox and Byzantine Catholic Compline services (Public Domain).
2. Audio Assets:
Release Chime (Glocke.ogg): Sourced from Wikimedia Commons.
Credit Format: "Glocke audio by [Author Name from Wikimedia, if applicable], sourced via Wikimedia Commons, used under [Applicable Creative Commons License, e.g., CC BY-SA 3.0]."
Guided Audio: "Watchfulness meditation generated via [Insert TTS Service Name]."
3. Theological Frameworks:
The Logismoi: Concept of the eight evil thoughts (Porneia, Acedia, etc.) attributed to Evagrius Ponticus (4th Century, Public Domain).
Nepsis (Watchfulness): Drawn from the Philokalia and the teachings of the Desert Fathers (Public Domain).

use the following to site the glocke.mp3
Date	7 November 2006 (upload date)
Source	Eigene Aufnahme einer Kirchenglocke
Author	Georg Hajdu
Licensing
I, the copyright holder of this work, hereby publish it under the following license:
w:en:Creative Commons
attribution share alike
This file is licensed under the Creative Commons Attribution-Share Alike 2.5 Generic license.
You are free:
to share – to copy, distribute and transmit the work
to remix – to adapt the work
Under the following conditions:
attribution – You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
share alike – If you remix, transform, or build upon the material, you must distribute your contributions under the same or compatible license as the original.
File history
Click on a date/time to view the file as it appeared at that time.

Date/Time	Thumbnail	Dimensions	User	Comment
current	18:28, 7 November 2006	
13 s (204 KB)	Georghajdu (talk | contribs)	{{Information |Description= |Source=Eigene Aufnahme einer Kirchenglocke |Date=7/11/2006 |Author=Georg Hajdu |Permission=Yes |other_versions= }}
