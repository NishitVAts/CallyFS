//
//  ContentView.swift
//  CallyFS
//
//  Created by Nishit Vats on 31/01/26.
//

import SwiftUI
import SwiftData

struct OnBoardingView: View {
    @StateObject var vm = OnboardingVM()
    @State var signInTapped = false
    @State var onboardingStep : OnboardingScreens = .applehealth
    let transition : AnyTransition = .asymmetric(insertion: .move(edge: .trailing) , removal: .move(edge: .leading))

    
    @State var selectedWeight: Measurement<UnitMass>?

    @Environment(\.locale) var locale

    // these are the hardcoded options for each measurement system...
    let imperialOptions = stride(from: 80, through: 600, by: 5).map {
        Measurement(value: Double($0), unit: UnitMass.pounds)
    }
    let metricOptions = stride(from: 80, through: 600, by: 5).map {
        Measurement(value: Double($0) / 2, unit: UnitMass.kilograms)
    }

    // here you determine which set of options to use
    var options: [Measurement<UnitMass>] {
        if locale.measurementSystem == .metric {
            return metricOptions
        } else {
            return imperialOptions
        }
    }

     
    // User data states
    @State var selectedSex : Sex = .notSet
    @State var selectedWorkoutRange : workoutRange = .nowAndThen
    @State var usedCalorieTrackingBeforeOrNot = false
    @State var heightInCm: String = ""
    @State var weightInKg: String = ""
    @State var dateOfBirth = Date()
    @State var selectedGoal: FitnessGoal = .maintain
    @State var selectedBarriers: Set<Barrier> = []
    @State var selectedDietRequirements: Set<DietRequirement> = []
    @State var userName: String = ""
    
    var body: some View {
        ZStack{
            content
        }
    }
    
    private var content : some View{
        VStack{
            // Progress indicator
            ProgressView(value: Double(onboardingStep.stepNumber), total: Double(OnboardingScreens.allCases.count))
                .padding(.horizontal)
                .padding(.top, 8)
            
            ZStack{
                switch onboardingStep {
                    
                case .applehealth:
                    permissionScreenView
                        .transition(transition)
                case .gender:
                    genderSelectionScreen
                        .transition(transition)
                case .workouts:
                    workoutScreen
                        .transition(transition)
                case .previousExperience:
                    previousExperienceScreen
                        .transition(transition)
                case .weightScreen:
                    weightScreen
                        .transition(transition)
                case .height:
                    heightScreenView
                        .transition(transition)
                case .dob:
                    dobScreen
                        .transition(transition)
                case .goalSelection:
                    goalSelectionScreen
                        .transition(transition)
                case .barriers:
                    barriersScreen
                        .transition(transition)
                case .specificDietRequirements:
                    dietRequirementsScreen
                        .transition(transition)
                case .userName:
                    userNameScreen
                        .transition(transition)
                case .thankyou:
                    thankYouScreen
                        .transition(transition)
                }
            }
            Spacer()
            
            // Continue button
            capsuleBars(textLabel: continueButtonText, bgColor: .black)
                .padding()
                .opacity(canContinue ? 1.0 : 0.5)
                .onTapGesture {
                    if canContinue {
                        withAnimation(.spring){
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            if onboardingStep == .applehealth {
                                Task {
                                    await vm.requestHealthAccessAndFetch()
                                }
                            }
                            else if let next = onboardingStep.next() {
                                
                                onboardingStep = next
                            }
                            else {
                                saveUserData()
                            }
                            
                        }
                    }
                }
        }
    }
    
    private var continueButtonText: String {
        if onboardingStep == .applehealth {
            return "Allow Permissions"
        }
        return "Continue"
    }
    
    private var canContinue: Bool {
        switch onboardingStep {
        case .applehealth:
            return true
        case .gender:
            return selectedSex != .notSet
        case .workouts:
            return true
        case .previousExperience:
            return true
        case .weightScreen:
            return !weightInKg.isEmpty && Double(weightInKg) != nil
        case .height:
            return !heightInCm.isEmpty &&  Double(heightInCm) != nil
        case .dob:
            return true
        case .goalSelection:
            return selectedGoal != .notSet
        case .barriers:
            return true // Optional selection
        case .specificDietRequirements:
            return true // Optional selection
        case .userName:
            return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case .thankyou:
            return true
        
        }
    }
    
    private func saveUserData() {
        // TODO: Save to UserProfile and persist data
        print("Saving user data:")
        print("Name: \(userName)")
        print("Sex: \(selectedSex)")
        print("Height: \(heightInCm) cm")
        print("Weight: \(weightInKg) kg")
        print("DOB: \(dateOfBirth)")
        print("Goal: \(selectedGoal)")
        print("Workout Frequency: \(selectedWorkoutRange)")
        print("Barriers: \(selectedBarriers)")
        print("Diet Requirements: \(selectedDietRequirements)")
    }
}

extension OnBoardingView{
    
    var heightScreenView: some View{
        ZStack{
            
        }
    }
    
    var permissionScreenView : some View {
        VStack(spacing: 30) {
            
            Spacer()
            
            Image("pandaRunning")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.7)
            
            Text("Connect to HealthKit")
                .font(.title.bold())
            
            Text("We’ll auto-fill your height, weight and age to personalize your plan.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            if vm.isLoading {
                ProgressView()
            }
            
            
            Spacer()
//            capsuleBars(textLabel: "Allow Permissions", bgColor: .black )
//                .onTapGesture {
//
//                }
        }
    }
    
    var firstScreen: some View{
        NavigationView{
            ZStack{
                VStack{
                    Spacer()
                    Text("Your personalized fitness journey starts here")
                        .font(.system(size: 30))
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    NavigationLink {
                        content
                    } label: {
                        Capsule()
                            .frame(height: 60)
                            .overlay(
                                Text("Get Started")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            )
                    }.buttonStyle(.plain)
                    
                    HStack{
                        Text("Already have an account?")
                        Text("**Sign In**").onTapGesture {
                            withAnimation {
                                signInTapped.toggle()
                            }
                        }
                    }
                }
                .padding()
                if signInTapped {
                    Color.gray.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                signInTapped.toggle()
                            }
                        }
                }
                signInSheet.offset(y: signInTapped ? UIScreen.main.bounds.height*0.3 : UIScreen.main.bounds.height*0.8 )
            }
        }
    }
    
    var workoutScreen : some View {
        VStack(alignment:.leading){
            
            Text("How many workouts do you do per week?")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            
            Text("This will be used to calibrate your custom plan")
                .padding(.trailing)
                .foregroundColor(.gray)
            Spacer()
            
            ForEach(workoutRange.allCases, id: \.self) { range in
                OptionButton(
                    selection: $selectedWorkoutRange,
                    value: range,
                    title: range.rawValue
                )
            }
            Spacer()
                
        }.padding()
    }
    
    var genderSelectionScreen : some View{
        VStack(alignment:.leading){
            Text("Choose your Gender")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            Text("This will be used to calibrate your custom plan")
                .padding(.trailing)
                .foregroundColor(.gray)
            Spacer()
            ForEach(Sex.allCases, id: \.self) { sex in
                OptionButton(
                    selection: $selectedSex,
                    value: sex,
                    title: sex.rawValue
                )
            }
            Spacer()
        }.padding()
    }
    
    var previousExperienceScreen : some View {
        VStack(alignment:.leading){
            Text("Have you tried other calorie tracking apps?")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            Text("This will help us personalize your experience")
                .padding(.trailing)
                .foregroundColor(.gray)
            Spacer()
            OptionButton(
                selection: $usedCalorieTrackingBeforeOrNot,
                value: false,
                title: "No, this is my first time"
            )
            OptionButton(
                selection: $usedCalorieTrackingBeforeOrNot,
                value: true,
                title: "Yes, I've used others before"
            )
            Spacer()
        }.padding()
    }
    
    var weightScreen: some View {
        VStack(alignment:.leading){
            Text("What's your height and weight?")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            Text("We need this to calculate your calorie needs")
                .padding(.trailing)
                .foregroundColor(.gray)
            
            Spacer()
            
            VStack(spacing: 20) {
                

                Picker("", selection: $selectedWeight) {
                    Text("Hide").tag(nil as Measurement<UnitMass>?)
                    
                    ForEach(options, id: \.self) { option in
                        Text(
                            option,
                            format: .measurement(width: .abbreviated, usage: .asProvided)
                        ).tag(option as Measurement<UnitMass>?)
                    }
                }
                .pickerStyle(.wheel)

            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(15)
            
            Spacer()
            
        }.padding()
    }
    
    var dobScreen: some View {
        VStack(alignment:.leading){
            Text("When were you born?")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            Text("We'll use this to personalize your goals")
                .padding(.trailing)
                .foregroundColor(.gray)
            
            Spacer()
            
            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            
            Spacer()
            
        }.padding()
    }
    
    var goalSelectionScreen: some View {
        VStack(alignment:.leading){
            Text("What's your main fitness goal?")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            Text("We'll tailor your plan to help you achieve it")
                .padding(.trailing)
                .foregroundColor(.gray)
            
            Spacer()
            
            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                OptionButton(
                    selection: $selectedGoal,
                    value: goal,
                    title: goal.displayName,
                    subtitle: goal.description
                )
            }
            
            Spacer()
            
        }.padding()
    }
    
    var barriersScreen: some View {
        VStack(alignment:.leading){
            Text("What challenges do you face?")
                .font(.system(size: 28))
                .fontWeight(.semibold)
            Text("Select all that apply - we'll help you overcome them")
                .padding(.trailing)
                .foregroundColor(.gray)
            
            Spacer()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Barrier.allCases, id: \.self) { barrier in
                        MultiSelectButton(
                            selection: $selectedBarriers,
                            value: barrier,
                            title: barrier.rawValue
                        )
                    }
                }
            }
            
            Spacer()
            
        }.padding()
    }
    
    var dietRequirementsScreen: some View {
        VStack(alignment:.leading){
            Text("Any dietary preferences?")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            Text("Select all that apply (optional)")
                .padding(.trailing)
                .foregroundColor(.gray)
            
            Spacer()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(DietRequirement.allCases, id: \.self) { requirement in
                        MultiSelectButton(
                            selection: $selectedDietRequirements,
                            value: requirement,
                            title: requirement.rawValue
                        )
                    }
                }
            }
            
            Spacer()
            
        }.padding()
    }
    
    var userNameScreen: some View {
        VStack(alignment:.leading){
            Text("What should we call you?")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            Text("Enter your name")
                .padding(.trailing)
                .foregroundColor(.gray)
            
            Spacer()
            
            TextField("Your name", text: $userName)
                .font(.title2)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(15)
            
            Spacer()
            
        }.padding()
    }
    
    var thankYouScreen: some View {
        VStack(spacing: 30){
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("Great job, \(userName)!")
                .font(.system(size: 32))
                .fontWeight(.bold)
            
            Text("Your personalized plan is ready. Let's connect with Apple Health to track your progress automatically.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
            
        }.padding()
    }
    
    var appleHealthScreen: some View {
        VStack(alignment: .leading, spacing: 20){
            Text("Connect Apple Health")
                .font(.system(size: 30))
                .fontWeight(.semibold)
            
            Text("Allow Cally to access your health data for a seamless experience")
                .foregroundColor(.gray)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                HealthPermissionRow(
                    icon: "figure.walk",
                    title: "Steps & Activity",
                    description: "Track your daily movement"
                )
                
                HealthPermissionRow(
                    icon: "heart.fill",
                    title: "Active Energy",
                    description: "Monitor calories burned"
                )
                
                HealthPermissionRow(
                    icon: "scalemass.fill",
                    title: "Body Measurements",
                    description: "Track weight and BMI"
                )
                
                HealthPermissionRow(
                    icon: "fork.knife",
                    title: "Nutrition",
                    description: "Log your meals and macros"
                )
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(15)
            
            Spacer()
            
            Text("You can change these permissions anytime in Settings")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
        }.padding()
    }
}

// MARK: - Supporting Views

struct HealthPermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Enums

enum workoutRange : String, CaseIterable  {
    case nowAndThen = "Workouts now and then"
    case few = "A few workouts per week"
    case athelete = "Dedicated Athlete"
}

enum OnboardingScreens: CaseIterable{
    case applehealth
    case gender
    case workouts
    case previousExperience
    case weightScreen
    case height
    case dob
    case goalSelection
    case barriers
    case specificDietRequirements
    case userName
    case thankyou
    
    var stepNumber: Int {
        OnboardingScreens.allCases.firstIndex(of: self) ?? 0
    }
    
    func next() -> OnboardingScreens? {
        let all = OnboardingScreens.allCases
        guard let index = all.firstIndex(of: self),
              index + 1 < all.count else { return nil }
        return all[index + 1]
    }
    
    func back() -> OnboardingScreens? {
        let all = OnboardingScreens.allCases
        guard let index = all.firstIndex(of: self),
              index - 1 > all.count else { return nil }
        return all[index - 1]
    }
}

enum FitnessGoal: String, CaseIterable {
    case notSet = "Not Set"
    case lose = "Lose Weight"
    case gain = "Gain Muscle"
    case maintain = "Maintain Weight"
    case improve = "Improve Fitness"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .notSet:
            return ""
        case .lose:
            return "Achieve a caloric deficit"
        case .gain:
            return "Build muscle with surplus"
        case .maintain:
            return "Stay at current weight"
        case .improve:
            return "Get stronger and healthier"
        }
    }
}

enum Barrier: String, CaseIterable {
    case timeConstraints = "Time Constraints"
    case motivation = "Staying Motivated"
    case tracking = "Consistent Tracking"
    case cookingSkills = "Cooking Skills"
    case budgetConstraints = "Budget Constraints"
    case socialSituations = "Social Situations"
}

enum DietRequirement: String, CaseIterable {
    case none = "No Restrictions"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case keto = "Keto"
    case paleo = "Paleo"
    case halal = "Halal"
    case kosher = "Kosher"
}

#Preview {
    OnBoardingView()
}

// MARK: - Reusable Components

struct OptionButton<T: Hashable>: View {
    @Binding var selection: T
    var value: T
    var title: String
    var subtitle: String?
    
    var isSelected: Bool {
        selection == value
    }
    
    init(selection: Binding<T>, value: T, title: String, subtitle: String? = nil) {
        self._selection = selection
        self.value = value
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(isSelected ? .black : .gray.opacity(0.05))
            .frame(height: 70)
            .overlay {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(isSelected ? .white : .black)
                        .font(.headline)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .gray)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
            }
            .onTapGesture {
                withAnimation(.bouncy) {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    selection = value
                }
            }
    }
}

struct MultiSelectButton<T: Hashable>: View {
    @Binding var selection: Set<T>
    var value: T
    var title: String
    
    var isSelected: Bool {
        selection.contains(value)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(isSelected ? .black : .gray.opacity(0.05))
            .frame(height: 60)
            .overlay {
                HStack {
                    Text(title)
                        .foregroundStyle(isSelected ? .white : .black)
                        .font(.headline)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            .onTapGesture {
                withAnimation(.bouncy) {
                    if isSelected {
                        selection.remove(value)
                    } else {
                        selection.insert(value)
                    }
                }
            }
    }
}

extension OnBoardingView {
    var signInSheet : some View {
        VStack{
            HStack{
                Spacer()
                Text("Sign In")
                    .font(.system(size: 24))
                Spacer()
            }
            
           Divider()
            VStack(spacing:10){
                capsuleBars()
                capsuleBars(textLabel:"Sign in with Google", bgColor: .white, strokeOrNot: true)
                capsuleBars(textLabel:"Sign in with Email")
                
            }
            
           Text("By Continuing you agree to Cally's Terms and Conditions and Privacy Policy")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding()
            
        }.padding()
        .background(.white)
            .cornerRadius(25)
            .padding(.horizontal,5)
    }
}

struct capsuleBars : View {
    var textLabel: String = "Sign in with Apple"
    var bgColor : Color = .black
    var strokeOrNot = false
    var body: some View {
        HStack{
            Capsule()
                .fill(bgColor)
                .stroke(strokeOrNot ? .gray : .clear)
                .frame(height: 60)
                .overlay(
                    Text(textLabel)
                        .foregroundColor(bgColor == .black ? .white : .black)
                        .font(.headline)
                )
        }
    }
}


