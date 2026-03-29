//
//  OnBoardingView.swift
//  CallyFS
//
//  Pure UI layer. All enums live in OnboardingModel.swift.
//

import SwiftUI
import HealthKit

// MARK: - Main Onboarding View

struct OnBoardingView: View {
    @StateObject var vm = OnboardingVM()
    @State private var onboardingStep: OnboardingScreens = .applehealth
    @State private var selectedWeight: Measurement<UnitMass>?
    @Environment(\.locale) var locale

    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )

    let imperialOptions = stride(from: 80, through: 600, by: 5).map {
        Measurement(value: Double($0), unit: UnitMass.pounds)
    }
    let metricOptions = stride(from: 40, through: 300, by: 1).map {
        Measurement(value: Double($0), unit: UnitMass.kilograms)
    }
    var weightOptions: [Measurement<UnitMass>] {
        locale.measurementSystem == .metric ? metricOptions : imperialOptions
    }

    @State private var selectedSex: Sex = .notSet
    @State private var selectedWorkoutRange: workoutRange = .nowAndThen
    @State private var usedCalorieTrackingBefore: Bool = false
    @State private var heightInCm: String = ""
    @State private var weightInKg: String = ""
    @State private var age: String = ""
    @State private var selectedGoal: FitnessGoal = .notSet
    @State private var selectedBarriers: Set<Barrier> = []
    @State private var selectedDietRequirements: Set<DietRequirement> = []
    @State private var userName: String = ""

    var body: some View {
        ZStack {
            Color(hex: "#0F0F0F").ignoresSafeArea()
            mainContent
        }
        .onAppear {
            syncViewStateWithVM()
        }
        .onChange(of: vm.weight) { newVal in 
            print("🔄 vm.weight changed: \(newVal)")
            if !newVal.isEmpty, let weightKg = Double(newVal) {
                weightInKg = newVal
                selectedWeight = Measurement(value: weightKg, unit: .kilograms)
                print("📝 Updated selectedWeight: \(weightKg) kg")
            }
        }
        .onChange(of: vm.height) { newVal in
            print("🔄 vm.height changed: \(newVal)")
            if let h = Double(newVal), h > 0, h < 10 {
                heightInCm = String(format: "%.0f", h * 100)
            } else {
                heightInCm = newVal
            }
        }
        .onChange(of: vm.sex) { newVal in 
            print("🔄 vm.sex changed: \(newVal.rawValue)")
            selectedSex = newVal 
        }
        .onChange(of: vm.age) { newVal in 
            print("🔄 vm.age changed: \(newVal)")
            age = newVal
        }
        .onChange(of: vm.userName) { newVal in 
            print("🔄 vm.userName changed: \(newVal)")
            if userName.isEmpty { userName = newVal } 
        }
    }
    
    private func syncViewStateWithVM() {
        print("🔄 Syncing view state with VM on appear...")
        
        if !vm.weight.isEmpty, let weightKg = Double(vm.weight) {
            weightInKg = vm.weight
            selectedWeight = Measurement(value: weightKg, unit: .kilograms)
            print("📝 Initialized selectedWeight: \(weightKg) kg")
        }
        
        if !vm.height.isEmpty, let h = Double(vm.height), h > 0, h < 10 {
            heightInCm = String(format: "%.0f", h * 100)
            print("📝 Initialized heightInCm: \(heightInCm) cm")
        }
        
        if vm.sex != .notSet {
            selectedSex = vm.sex
            print("📝 Initialized selectedSex: \(vm.sex.rawValue)")
        }
        
        if !vm.age.isEmpty {
            age = vm.age
            print("📝 Initialized age: \(vm.age)")
        }
        
        if !vm.userName.isEmpty {
            userName = vm.userName
            print("📝 Initialized userName: \(vm.userName)")
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            topBar
            ZStack {
            
               switch onboardingStep {
                case .applehealth:            permissionScreenView.transition(transition)
                case .gender:                 genderSelectionScreen.transition(transition)
                case .workouts:               workoutScreen.transition(transition)
                case .previousExperience:     previousExperienceScreen.transition(transition)
                case .weightScreen:           weightScreen.transition(transition)
                case .height:                 heightScreenView.transition(transition)
                case .dob:                    dobScreen.transition(transition)
                case .goalSelection:          goalSelectionScreen.transition(transition)
                case .barriers:               barriersScreen.transition(transition)
                case .specificDietRequirements: dietRequirementsScreen.transition(transition)
                case .userName:               userNameScreen.transition(transition)
                case .thankyou:               thankYouScreen.transition(transition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            continueButton
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                if onboardingStep != .applehealth {
                    Button(action: goBack) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#1C1C1C"))
                                .frame(width: 38, height: 38)
                                .overlay(Circle().stroke(Color(hex: "#2C2C2C"), lineWidth: 1))
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#C0C0C0"))
                        }
                    }
                } else {
                    Spacer().frame(width: 38)
                }
                Spacer()
                Text("Step \(onboardingStep.stepNumber + 1) of \(OnboardingScreens.allCases.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#666666"))
                    .monospacedDigit()
                Spacer()
                Spacer().frame(width: 38)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#1E1E1E")).frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [Color(hex: "#E0E0E0"), Color(hex: "#909090")],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progressFraction, height: 3)
                        .animation(.spring(response: 0.5), value: onboardingStep.stepNumber)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }

    private var progressFraction: Double {
        Double(onboardingStep.stepNumber + 1) / Double(OnboardingScreens.allCases.count)
    }

    // MARK: - Navigation

    private func goBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if let prev = onboardingStep.back() { onboardingStep = prev }
        }
    }

    private func goForward() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if onboardingStep == .applehealth {
                Task {
                    await vm.requestHealthAccessAndFetch()
                    if let next = onboardingStep.next() { 
                        onboardingStep = next 
                    }
                }
            } else if let next = onboardingStep.next() {
                onboardingStep = next
            } else {
                finalizeOnboarding()
            }
        }
    }

    private func finalizeOnboarding() {
        vm.userName = userName
        vm.sex = selectedSex
        vm.age = age
        if let h = Double(heightInCm), h > 0 {
            vm.height = String(format: "%.4f", h / 100.0)
        }
        if let measurement = selectedWeight {
            vm.weight = String(format: "%.1f", measurement.converted(to: .kilograms).value)
        }
        vm.finalizeAndSave(
            workouts: selectedWorkoutRange,
            goal: selectedGoal,
            hasTrackedBefore: usedCalorieTrackingBefore,
            barriers: selectedBarriers,
            dietRequirements: selectedDietRequirements
        )
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: { if canContinue { goForward() } }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(canContinue ? Color.white : Color(hex: "#2A2A2A"))
                    .frame(height: 58)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#3A3A3A"), lineWidth: canContinue ? 0 : 1)
                    )
                if vm.isLoading {
                    ProgressView().tint(.black)
                } else {
                    HStack(spacing: 8) {
                        Text(continueButtonText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(canContinue ? .black : Color(hex: "#555555"))
                        if canContinue && onboardingStep != .applehealth {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
        .disabled(!canContinue || vm.isLoading)
        .animation(.easeInOut(duration: 0.2), value: canContinue)
    }

    private var continueButtonText: String {
        switch onboardingStep {
        case .applehealth: return "Connect Apple Health"
        case .thankyou:    return "Get Started"
        default:           return "Continue"
        }
    }

    private var canContinue: Bool {
        switch onboardingStep {
        case .applehealth:              return true
        case .gender:                   return selectedSex != .notSet
        case .workouts:                 return true
        case .previousExperience:       return true
        case .weightScreen:             return selectedWeight != nil
        case .height:
            guard let h = Double(heightInCm) else { return false }
            return h > 50 && h < 300
        case .dob:
            guard let ageInt = Int(age) else { return false }
            return ageInt >= 13 && ageInt <= 120
        case .goalSelection:            return selectedGoal != .notSet
        case .barriers:                 return true
        case .specificDietRequirements: return true
        case .userName:                 return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case .thankyou:                 return true
        }
    }
}

// MARK: - Screen Implementations

extension OnBoardingView {

    var permissionScreenView: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "#161616"))
                    .frame(width: 110, height: 110)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF4444")],
                        startPoint: .top, endPoint: .bottom))
            }
            Spacer().frame(height: 32)
            OnboardingHeader(title: "Connect to HealthKit",
                             subtitle: "We'll automatically pre-fill your profile with your health data.")
                .padding(.horizontal, 20)
            Spacer().frame(height: 36)
            VStack(spacing: 10) {
                DarkPermissionRow(icon: "person.fill",    title: "Personal Info",     description: "Age, sex, and date of birth")
                DarkPermissionRow(icon: "scalemass.fill", title: "Body Measurements", description: "Height and weight")
                DarkPermissionRow(icon: "figure.walk",    title: "Steps & Activity",  description: "Daily movement tracking")
                DarkPermissionRow(icon: "fork.knife",     title: "Nutrition Data",    description: "Calories and macros")
            }
            .padding(.horizontal, 20)
            if let error = vm.errorMessage {
                Text(error).font(.system(size: 12)).foregroundColor(Color(hex: "#FF6B6B"))
                    .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.top, 12)
            }
            Spacer()
        }
    }

    var genderSelectionScreen: some View {
        OnboardingScreenWrapper(title: "Choose your Gender", subtitle: selectedSex != .notSet ? "Pre-filled from HealthKit" : "This will be used to calibrate your custom plan") {
            VStack(spacing: 10) {
                ForEach(Sex.allCases.filter { $0 != .notSet }, id: \.self) { sex in
                    DarkOptionButton(selection: $selectedSex, value: sex, title: sex.rawValue,
                                     icon: sex == .male ? "figure.stand" : sex == .female ? "figure.stand.dress" : "person.fill.questionmark")
                }
            }
        }
    }

    var workoutScreen: some View {
        OnboardingScreenWrapper(title: "How many workouts per week?", subtitle: "This will calibrate your activity multiplier") {
            VStack(spacing: 10) {
                DarkOptionButton(selection: $selectedWorkoutRange, value: .nowAndThen,
                                 title: workoutRange.nowAndThen.rawValue, subtitle: "1-2 days/week", icon: "flame")
                DarkOptionButton(selection: $selectedWorkoutRange, value: .few,
                                 title: workoutRange.few.rawValue, subtitle: "3-5 days/week", icon: "bolt.fill")
                DarkOptionButton(selection: $selectedWorkoutRange, value: .athelete,
                                 title: workoutRange.athelete.rawValue, subtitle: "6+ days/week", icon: "trophy.fill")
            }
        }
    }

    var previousExperienceScreen: some View {
        OnboardingScreenWrapper(title: "Tried calorie tracking before?", subtitle: "This will help us personalize your experience") {
            VStack(spacing: 10) {
                DarkOptionButton(selection: $usedCalorieTrackingBefore, value: false,
                                 title: "No, this is my first time", icon: "star.fill")
                DarkOptionButton(selection: $usedCalorieTrackingBefore, value: true,
                                 title: "Yes, I've used others before", icon: "checkmark.seal.fill")
            }
        }
    }

    var weightScreen: some View {
        OnboardingScreenWrapper(title: "What's your weight?", subtitle: selectedWeight != nil ? "Pre-filled from HealthKit" : "We need this to calculate your calorie needs") {
            VStack(spacing: 0) {
                HStack {
                    Text(locale.measurementSystem == .metric ? "KILOGRAMS" : "POUNDS")
                        .font(.system(size: 11, weight: .medium)).foregroundColor(Color(hex: "#666666")).tracking(1.5)
                    Spacer()
                    if selectedWeight != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#4CAF50"))
                            Text("Pre-filled")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#4CAF50"))
                        }
                    }
                }
                .padding(.bottom, 12)
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#161616"))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                    RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#222222"))
                        .frame(height: 44).padding(.horizontal, 12)
                    Picker("", selection: $selectedWeight) {
                        Text("Select").tag(nil as Measurement<UnitMass>?)
                        ForEach(weightOptions, id: \.self) { option in
                            Text(option, format: .measurement(width: .abbreviated, usage: .asProvided))
                                .tag(option as Measurement<UnitMass>?)
                        }
                    }
                    .pickerStyle(.wheel).colorScheme(.dark).padding(.horizontal, 8)
                }
                .frame(height: 200)
            }
        }
    }

    var heightScreenView: some View {
        OnboardingScreenWrapper(title: "What's your height?", subtitle: !heightInCm.isEmpty ? "Pre-filled from HealthKit" : "We need this to calculate your BMI and calorie needs") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("HEIGHT (CM)").font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#666666")).tracking(1.5)
                    Spacer()
                    if !heightInCm.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#4CAF50"))
                            Text("Pre-filled")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#4CAF50"))
                        }
                    }
                }
                HStack {
                    TextField("e.g. 175", text: $heightInCm)
                        .font(.system(size: 32, weight: .bold)).foregroundColor(.white).keyboardType(.decimalPad)
                    Text("cm").font(.system(size: 18, weight: .medium)).foregroundColor(Color(hex: "#666666"))
                }
                Divider().background(Color(hex: "#2A2A2A"))
            }
            .padding(20).background(Color(hex: "#161616")).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                (Double(heightInCm) != nil && !heightInCm.isEmpty) ? Color(hex: "#C0C0C0") : Color(hex: "#2A2A2A"), lineWidth: 1))
        }
    }

    var dobScreen: some View {
        let isPreFilled = !age.isEmpty && Int(age) ?? 0 > 0
        return OnboardingScreenWrapper(title: "What's your age?", subtitle: isPreFilled ? "Pre-filled from HealthKit" : "We'll use this to personalize your goals") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AGE (YEARS)").font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#666666")).tracking(1.5)
                    Spacer()
                    if isPreFilled {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#4CAF50"))
                            Text("Pre-filled")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#4CAF50"))
                        }
                    }
                }
                HStack {
                    TextField("e.g. 25", text: $age)
                        .font(.system(size: 32, weight: .bold)).foregroundColor(.white).keyboardType(.numberPad)
                    Text("years").font(.system(size: 18, weight: .medium)).foregroundColor(Color(hex: "#666666"))
                }
                Divider().background(Color(hex: "#2A2A2A"))
            }
            .padding(20).background(Color(hex: "#161616")).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                (Int(age) != nil && !age.isEmpty) ? Color(hex: "#C0C0C0") : Color(hex: "#2A2A2A"), lineWidth: 1))
        }
    }

    var goalSelectionScreen: some View {
        OnboardingScreenWrapper(title: "What's your main fitness goal?", subtitle: "We'll tailor your plan to help you achieve it") {
            VStack(spacing: 10) {
                DarkOptionButton(selection: $selectedGoal, value: .lose,
                                 title: FitnessGoal.lose.displayName, subtitle: FitnessGoal.lose.description,
                                 icon: "arrow.down.circle.fill")
                DarkOptionButton(selection: $selectedGoal, value: .gain,
                                 title: FitnessGoal.gain.displayName, subtitle: FitnessGoal.gain.description,
                                 icon: "arrow.up.circle.fill")
                DarkOptionButton(selection: $selectedGoal, value: .maintain,
                                 title: FitnessGoal.maintain.displayName, subtitle: FitnessGoal.maintain.description,
                                 icon: "equal.circle.fill")
                DarkOptionButton(selection: $selectedGoal, value: .improve,
                                 title: FitnessGoal.improve.displayName, subtitle: FitnessGoal.improve.description,
                                 icon: "bolt.circle.fill")
            }
        }
    }

    var barriersScreen: some View {
        OnboardingScreenWrapper(title: "What challenges do you face?", subtitle: "Select all that apply") {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Barrier.allCases, id: \.self) { barrier in
                        DarkMultiSelectButton(selection: $selectedBarriers, value: barrier, title: barrier.rawValue)
                    }
                }
            }
        }
    }

    var dietRequirementsScreen: some View {
        OnboardingScreenWrapper(title: "Any dietary preferences?", subtitle: "Select all that apply (optional)") {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(DietRequirement.allCases, id: \.self) { req in
                        DarkMultiSelectButton(selection: $selectedDietRequirements, value: req, title: req.rawValue)
                    }
                }
            }
        }
    }

    var userNameScreen: some View {
        OnboardingScreenWrapper(title: "What should we call you?", subtitle: "Enter your name to get started") {
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR NAME").font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#666666")).tracking(1.5)
                TextField("e.g. John", text: $userName)
                    .font(.system(size: 28, weight: .bold)).foregroundColor(.white).autocorrectionDisabled()
                Divider().background(Color(hex: "#2A2A2A"))
            }
            .padding(20).background(Color(hex: "#161616")).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                !userName.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: "#C0C0C0") : Color(hex: "#2A2A2A"),
                lineWidth: 1))
        }
    }

    var thankYouScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle().fill(Color(hex: "#161616")).frame(width: 110, height: 110)
                    .overlay(Circle().stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                Image(systemName: "checkmark").font(.system(size: 44, weight: .bold)).foregroundColor(.white)
            }
            Spacer().frame(height: 36)
            Text("You're all set,").font(.custom("Georgia", size: 16)).foregroundColor(Color(hex: "#888888"))
            Text(userName.isEmpty ? "Legend." : "\(userName).").font(.system(size: 36, weight: .black))
                .foregroundColor(.white).padding(.top, 4)
            Spacer().frame(height: 20)
            Text("Your personalized plan is ready.\nLet's build something great.")
                .font(.system(size: 15)).foregroundColor(Color(hex: "#777777"))
                .multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 40)
            Spacer().frame(height: 48)
          
            Spacer()
        }
    }
}

// MARK: - Reusable Components

struct OnboardingScreenWrapper<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(title: title, subtitle: subtitle).padding(.horizontal, 20)
            Spacer().frame(height: 28)
            content.padding(.horizontal, 20)
            Spacer()
        }
        .padding(.top, 16)
    }
}

struct OnboardingHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.system(size: 14)).foregroundColor(Color(hex: "#777777"))
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DarkOptionButton<T: Hashable>: View {
    @Binding var selection: T
    let value: T
    let title: String
    var subtitle: String? = nil
    var icon: String = "circle"
    var isSelected: Bool { selection == value }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selection = value
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color(hex: "#333333") : Color(hex: "#1A1A1A"))
                        .frame(width: 40, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color(hex: "#555555") : Color(hex: "#2A2A2A"), lineWidth: 1))
                    Image(systemName: icon).font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? .white : Color(hex: "#666666"))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color(hex: "#BBBBBB"))
                    if let sub = subtitle {
                        Text(sub).font(.system(size: 12))
                            .foregroundColor(isSelected ? Color(hex: "#999999") : Color(hex: "#555555"))
                    }
                }
                Spacer()
                ZStack {
                    Circle().stroke(isSelected ? Color.white : Color(hex: "#3A3A3A"), lineWidth: 1.5).frame(width: 20, height: 20)
                    if isSelected { Circle().fill(Color.white).frame(width: 10, height: 10) }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color(hex: "#1E1E1E") : Color(hex: "#141414"))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color(hex: "#454545") : Color(hex: "#222222"), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct DarkMultiSelectButton<T: Hashable>: View {
    @Binding var selection: Set<T>
    let value: T
    let title: String
    var isSelected: Bool { selection.contains(value) }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if isSelected { selection.remove(value) } else { selection.insert(value) }
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.white : Color(hex: "#3A3A3A"), lineWidth: 1.5).frame(width: 22, height: 22)
                    if isSelected { RoundedRectangle(cornerRadius: 5).fill(Color.white).frame(width: 14, height: 14) }
                }
                Text(title).font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "#BBBBBB"))
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color(hex: "#1E1E1E") : Color(hex: "#141414"))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color(hex: "#454545") : Color(hex: "#222222"), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct DarkPermissionRow: View {
    let icon: String
    let title: String
    let description: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#1E1E1E")).frame(width: 42, height: 42)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                Image(systemName: icon).font(.system(size: 16, weight: .medium)).foregroundColor(Color(hex: "#C0C0C0"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(description).font(.system(size: 12)).foregroundColor(Color(hex: "#666666"))
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundColor(Color(hex: "#555555"))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(hex: "#161616")).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#242424"), lineWidth: 1))
    }
}

// MARK: - Preview

#Preview {
    OnBoardingView().preferredColorScheme(.dark)
}
