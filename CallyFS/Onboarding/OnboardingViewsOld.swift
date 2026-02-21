////
////  OnboardingViews.swift
////  CallyFS
////
////  Created by Nishit Vats on 31/01/26.
////
//
//import SwiftUI
//import HealthKit
//
//
//struct OnboardingViews: View {
//    @StateObject private var vm = OnboardingVM()
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Color.backgroundColor
//                    .ignoresSafeArea()
//                
//                content
//            }
//            .animation(.easeInOut, value: vm.currentStep)
//        }
//    }
//}
//
//// MARK: - Step Switcher
//extension OnboardingViews {
//    
//    @ViewBuilder
//    var content: some View {
//        switch vm.currentStep {
//        case .welcome:
//            welcomeView
//        case .permission:
//            permissionView
//        case .profileInput:
//            profileInputView
//        case .goals:
//            goalsView
//        }
//    }
//}
//
//extension OnboardingViews {
//    
//    func primaryButton(title: String, action: @escaping () -> Void) -> some View {
//        Button(action: action) {
//            RoundedRectangle(cornerRadius: 25)
//                .fill(Color.green)
//                .frame(height: 55)
//                .overlay(
//                    Text(title)
//                        .foregroundColor(.white)
//                        .font(.system(size: 18, weight: .semibold))
//                )
//                .padding(.horizontal)
//        }
//    }
//    
//    func textField(_ title: String, text: Binding<String>) -> some View {
//        TextField(title, text: text)
//            .keyboardType(.decimalPad)
//            .padding()
//            .background(Color.white)
//            .cornerRadius(12)
//    }
//    
//    func goalRow(title: String, value: Double, unit: String) -> some View {
//        HStack {
//            Text(title)
//            Spacer()
//            Text("\(Int(value)) \(unit)")
//                .fontWeight(.semibold)
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(12)
//    }
//}
//
//extension OnboardingViews {
//    var goalsView: some View {
//        VStack(spacing: 25) {
//            
//            Text("Your Daily Targets")
//                .font(.title.bold())
//
//            goalRow(title: "Calories", value: vm.targetCalories, unit: "kcal")
//            goalRow(title: "Protein", value: vm.targetProtein, unit: "g")
//            goalRow(title: "Carbs", value: vm.targetCarbs, unit: "g")
//            goalRow(title: "Fat", value: vm.targetFat, unit: "g")
//            
//            primaryButton(title: "Finish") {
//                vm.nextStep()
//            }
//        }
//        .padding()
//    }
//}
//
//
//extension OnboardingViews {
//    
//    var profileInputView: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                
//                Text("Tell Us About You")
//                    .font(.title.bold())
//                
//                textField("Your Name", text: $vm.userName)
//                textField("Age", text: $vm.age)
//                textField("Weight (kg)", text: $vm.weight)
//                textField("Height (m)", text: $vm.height)
//                
//                Picker("Sex", selection: $vm.sex) {
//                    ForEach(Sex.allCases, id: \.self) {
//                        Text($0.rawValue)
//                    }
//                }
//                .pickerStyle(.segmented)
//                
//                primaryButton(title: "Continue") {
//                    vm.nextStep()
//                }
//            }
//            .padding()
//        }
//    }
//}
//
//
//extension OnboardingViews {
//    
//    var permissionView: some View {
//        VStack(spacing: 30) {
//            
//            Spacer()
//            
//            Image("pandaRunning")
//                .resizable()
//                .scaledToFit()
//                .frame(width: UIScreen.main.bounds.width * 0.7)
//            
//            Text("Connect to HealthKit")
//                .font(.title.bold())
//            
//            Text("We’ll auto-fill your height, weight and age to personalize your plan.")
//                .multilineTextAlignment(.center)
//                .foregroundColor(.gray)
//                .padding(.horizontal)
//            
//            if vm.isLoading {
//                ProgressView()
//            }
//            
//            primaryButton(title: "Allow Access") {
//                Task {
////                    await vm.requestHealthAccessAndFetch()
//                }
//            }
//            
//            Spacer()
//        }
//    }
//}
//
//
//extension OnboardingViews {
//    
//    var welcomeView: some View {
//        VStack(spacing: 30) {
//            
//            Spacer()
//            
//            
//            
//            VStack(spacing: 12) {
//                Text("Welcome to Bamboo")
//                    .font(.system(size: 26, weight: .bold, design: .rounded))
//                
//                Text("Track your calories with ease. Your panda companion is ready to help.")
//                    .multilineTextAlignment(.center)
//                    .font(.system(size: 16))
//                    .foregroundColor(.gray)
//            }
//            .padding(.horizontal)
//            
//            Spacer()
//            
//            primaryButton(title: "Get Started") {
//                vm.nextStep()
//            }
//            
//            Spacer()
//        }
//    }
//}
//
//
//
//
//extension Color {
//    static let backgroundColor =  Color.init(red: 0.93, green: 0.93, blue: 0.91)
//}
//
//
//
//
//#Preview {
//    OnboardingViews()
//}
