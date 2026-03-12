//
//  Home.swift
//  CallyFS
//

import SwiftUI

struct DashboardView: View {
    @StateObject var vm = DashboardViewModel()
    @State private var selectedTab = 0
    @State private var showAddCard = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0F0F0F").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vm.greetingText)
                                        .font(.custom("Georgia", size: 14))
                                        .foregroundColor(Color(hex: "#888888"))
                                    Text(vm.userName)
                                        .font(.custom("Georgia-Bold", size: 24))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                HStack(spacing: 14) {
                                    Button(action: { 
                                        HapticManager.shared.settingsTap()
                                        showSettings = true 
                                    }) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color(hex: "#AAAAAA"))
                                            .frame(width: 44, height: 44)
                                            .background(Color(hex: "#1A1A1A"))
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            CalorieCard(vm: vm)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)

                            HStack(spacing: 14) {
                                ForEach(vm.macros) { MacroCard(macro: $0) }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 18)

                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Today's Meals")
                                        .font(.custom("Georgia-Bold", size: 20))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(Date(), style: .date)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(hex: "#666666"))
                                }
                                .padding(.horizontal, 24)

                                ForEach(vm.mealSlots) { slot in
                                    NavigationLink(destination: MealDetailView(vm: vm, slotType: slot.type)) {
                                        MealSlotCard(slot: slot)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 24)
                                }
                            }
                            .padding(.top, 32)

                            Spacer().frame(height: showAddCard ? 40 : 120)
                        }
                    }
                    
                    if !showAddCard {
                        BottomNav(selectedTab: $selectedTab, onFABTap: {
                            HapticManager.shared.fabTap()
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                                showAddCard = true
                            }
                        })
                        .transition(
                            .asymmetric(
                                insertion: .modifier(
                                    active: ShutterFromBottom(progress: 0),
                                    identity: ShutterFromBottom(progress: 1)
                                ),
                                removal: .modifier(
                                    active: ShutterFromBottom(progress: 0),
                                    identity: ShutterFromBottom(progress: 1)
                                )
                            )
                        )
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.72), value: showAddCard)
                
                if showAddCard {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            HapticManager.shared.cardDismiss()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                showAddCard = false
                            }
                        }

                    VStack {
                        AddMealCard(vm: vm, isPresented: $showAddCard)
                           
                        Spacer()
                    } .transition(
                        .asymmetric(
                            insertion: .modifier(
                                active: ShutterFromTop(progress: 0),
                                identity: ShutterFromTop(progress: 1)
                            ),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .onAppear { vm.load() }
        .sheet(isPresented: $showSettings) {
//            SettingsView()
        }
    }
}

// MARK: - Shutter Transition Modifier

// For AddMealCard — opens/closes from top
struct ShutterFromTop: ViewModifier, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content
            .scaleEffect(y: progress, anchor: .top)
            .opacity(progress < 0.01 ? 0 : 1)
    }
}

// For BottomNav — opens/closes from bottom
struct ShutterFromBottom: ViewModifier, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content
            .scaleEffect(y: progress, anchor: .bottom)
            .opacity(progress < 0.01 ? 0 : 1)
    }
}

// MARK: - Meal Slot Card

struct MealSlotCard: View {
    let slot: MealSlot

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#1A1A1A"))
                    .frame(width: 56, height: 56)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                Text(slot.type.emoji).font(.system(size: 26))
                    .frame(width: 56, height: 56)

                if slot.isLogged {
                    Circle().fill(Color.white).frame(width: 18, height: 18)
                        .overlay(Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(.black))
                        .shadow(color: .black.opacity(0.2), radius: 2)
                        .offset(x: 8, y: -8)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(slot.type.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                if slot.isLogged {
                    let hasCalculating = slot.items.contains(where: { $0.kcal == 0 })
                    if hasCalculating {
                        Text("Calculating...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#888888"))
                            .shimmer()
                    } else {
                        HStack(spacing: 8) {
                            Text("\(slot.items.count) item\(slot.items.count == 1 ? "" : "s")")
                                .font(.system(size: 13)).foregroundColor(Color(hex: "#999999"))
                            Circle().fill(Color(hex: "#444444")).frame(width: 3, height: 3)
                            Text("\(slot.totalKcal) kcal")
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                } else {
                    Text("Tap to add food")
                        .font(.system(size: 13)).foregroundColor(Color(hex: "#666666"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#555555"))
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#151515")))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#252525"), lineWidth: 1))
    }
}

// MARK: - Meal Detail View

struct MealDetailView: View {
    @ObservedObject var vm: DashboardViewModel
    let slotType: MealSlot.SlotType
    @Environment(\.dismiss) var dismiss

    var slot: MealSlot {
        vm.mealSlots.first { $0.type == slotType } ?? MealSlot(type: slotType)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#0F0F0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Nav bar
                    HStack(spacing: 14) {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle().fill(Color(hex: "#1C1C1C")).frame(width: 38, height: 38)
                                    .overlay(Circle().stroke(Color(hex: "#2C2C2C"), lineWidth: 1))
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "#C0C0C0"))
                            }
                        }
                        Text(slotType.emoji).font(.system(size: 22))
                        Text(slotType.rawValue)
                            .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        if slot.isLogged {
                            Text("\(slot.totalKcal) kcal")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#999999"))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color(hex: "#1E1E1E"))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if slot.items.isEmpty {
                        VStack(spacing: 14) {
                            Spacer().frame(height: 60)
                            Text(slotType.emoji).font(.system(size: 52))
                            Text("Nothing logged yet")
                                .font(.system(size: 17, weight: .semibold)).foregroundColor(Color(hex: "#888888"))
                            Text("Tap below to add your first item")
                                .font(.system(size: 13)).foregroundColor(Color(hex: "#555555"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(slot.items) { item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#1E1E1E")).frame(width: 40, height: 40)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                                        Text(item.emoji).font(.system(size: 18))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                        if item.kcal == 0 {
                                            Text("Calculating...")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(Color(hex: "#888888"))
                                                .shimmer()
                                        } else {
                                            Text(item.time, style: .time)
                                                .font(.system(size: 11)).foregroundColor(Color(hex: "#555555"))
                                        }
                                    }
                                    Spacer()
                                    if item.kcal == 0 {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#666666"))
                                            .shimmer()
                                    } else {
                                        Text("\(item.kcal) kcal")
                                            .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "#AAAAAA"))
                                    }
                                    Button(action: { 
                                        HapticManager.shared.deleteItem()
                                        vm.deleteItem(item, from: slotType) 
                                    }) {
                                        Image(systemName: "trash").font(.system(size: 13))
                                            .foregroundColor(Color(hex: "#444444")).frame(width: 32, height: 32)
                                    }
                                }
                                .padding(12)
                                .background(Color(hex: "#161616")).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#222222"), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                    Spacer().frame(height: 110)
                }
            }

            // Add button
            Button(action: { vm.openSheet(for: slotType) }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text("Add Food Item").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(Color(hex: "#1C1C1C")).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#2C2C2C"), lineWidth: 1))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Add Meal Card

struct AddMealCard: View {
    @ObservedObject var vm: DashboardViewModel
    @Binding var isPresented: Bool
    @State private var mealName = ""
    @State private var selectedCategory: MealSlot.SlotType = .breakfast
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Add Meal")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        HapticManager.shared.cardDismiss()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#999999"))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "#1A1A1A"))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHAT DID YOU EAT?")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#666666"))
                        .tracking(1.2)
                    
                    TextField("e.g. Grilled Chicken Salad", text: $mealName)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .focused($isNameFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(18)
                        .background(Color(hex: "#1A1A1A"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isNameFocused ? Color.white.opacity(0.3) : Color(hex: "#2A2A2A"), lineWidth: 1.5)
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("MEAL TYPE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#666666"))
                        .tracking(1.2)
                    
                    Menu {
                        ForEach(MealSlot.SlotType.allCases, id: \.self) { category in
                            Button(action: {
                                HapticManager.shared.categorySelection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            }) {
                                HStack {
                                    Text(category.emoji)
                                    Text(category.rawValue)
                                    if selectedCategory == category {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory.emoji)
                                .font(.system(size: 24))
                            Text(selectedCategory.rawValue)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#666666"))
                        }
                        .padding(18)
                        .background(Color(hex: "#1A1A1A"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#2A2A2A"), lineWidth: 1.5)
                        )
                    }
                }
                
                Button(action: {
                    vm.activeSlot = selectedCategory
                    vm.inputName = mealName
                    vm.inputKcal = ""
                    vm.confirmAdd()
                    
                    HapticManager.shared.logMeal()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isPresented = false
                    }
                    
                    mealName = ""
                    selectedCategory = .breakfast
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Log Meal")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(mealName.isEmpty ? Color(hex: "#666666") : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(mealName.isEmpty ? Color(hex: "#222222") : Color.white)
                    .cornerRadius(16)
                }
                .disabled(mealName.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: mealName.isEmpty)
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.top, 60)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "#0F0F0F"))
                .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color(hex: "#2A2A2A"), lineWidth: 1)
        )
        
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isNameFocused = true
            }
        }
    }
}

// MARK: - Calorie Card

struct CalorieCard: View {
    @ObservedObject var vm: DashboardViewModel
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color(hex: "#1C1C1C"), Color(hex: "#121212")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(colors: [Color(hex: "#3A3A3A"), Color(hex: "#222222")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))

            GeometryReader { geo in
                DiagonalPattern()
                    .frame(width: geo.size.width * 0.5, height: geo.size.height)
                    .frame(maxWidth: .infinity, alignment: .trailing).opacity(0.05)
            }.clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Daily").font(.custom("Georgia", size: 15)).foregroundColor(Color(hex: "#999999"))
                        Text("CALORIES").font(.custom("Georgia-Bold", size: 15))
                            .foregroundColor(Color(hex: "#DDDDDD")).tracking(1.8)
                    }
                    Spacer()
                }
                Spacer().frame(height: 22)
                Text("Eaten \(Int(vm.eatenKcal))")
                    .font(.custom("Georgia", size: 14)).foregroundColor(Color(hex: "#888888"))
                Spacer().frame(height: 8)
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("\(vm.kcalLeft)")
                        .font(.system(size: 64, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("KCAL LEFT").font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#AAAAAA")).tracking(1.2).padding(.bottom, 10)
                }
                Spacer().frame(height: 22)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#252525")).frame(height: 40)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [Color(hex: "#FFFFFF"), Color(hex: "#BBBBBB")],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * vm.calorieProgress, height: 40)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: vm.calorieProgress)
                        if vm.eatenKcal > 0 {
                            Text("\(Int(vm.eatenKcal)) KCAL")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(Color(hex: "#0F0F0F"))
                                .padding(.leading, 14)
                        }
                    }
                }.frame(height: 40)
            }.padding(24)
        }.frame(height: 240)
    }
}

// MARK: - Macro Card

struct MacroCard: View {
    let macro: MacroNutrient
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(macro.name).font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "#999999"))
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(macro.currentInt)").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(" / \(macro.totalInt)g").font(.system(size: 13)).foregroundColor(Color(hex: "#777777"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#252525")).frame(height: 5)
                    RoundedRectangle(cornerRadius: 4).fill(macro.color)
                        .frame(width: geo.size.width * macro.progress, height: 5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: macro.progress)
                }
            }.frame(height: 5)
        }
        .padding(14).background(Color(hex: "#151515")).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
    }
}

// MARK: - Bottom Nav

struct BottomNav: View {
    @Binding var selectedTab: Int
    var onFABTap: () -> Void
    let items: [(String, Int)] = [("house.fill",0),("chart.pie.fill",1),("plus",2),("calendar",3),("person.fill",4)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.1) { icon, tag in
                if tag == 2 {
                    Button(action: onFABTap) {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 58, height: 58)
                                .shadow(color: .white.opacity(0.2), radius: 12, y: 2)
                            Image(systemName: icon).font(.system(size: 24, weight: .bold)).foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 10).offset(y: -8)
                } else {
                    Button(action: { 
                        HapticManager.shared.fabTap()
                        selectedTab = tag
                    }) {
                        Image(systemName: icon)
                            .font(.system(size: 21, weight: selectedTab == tag ? .semibold : .regular))
                            .foregroundColor(selectedTab == tag ? .white : Color(hex: "#666666"))
                            .frame(maxWidth: .infinity).frame(height: 60)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "#151515"))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#2A2A2A"), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Diagonal Pattern

struct DiagonalPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
            let count = Int(size.width / spacing) + Int(size.height / spacing) + 2
            for i in 0..<count {
                let x = CGFloat(i) * spacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x - size.height, y: size.height))
                context.stroke(path, with: .color(.white), lineWidth: 1)
            }
        }
    }
}

// MARK: - Meal Picker Sheet (FAB → choose which slot)

struct MealPickerSheet: View {
    @ObservedObject var vm: DashboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add to which meal?")
                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                .padding(.top, 8)

            ForEach(MealSlot.SlotType.allCases, id: \.self) { slotType in
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        vm.openSheet(for: slotType)
                    }
                }) {
                    HStack(spacing: 14) {
                        Text(slotType.emoji).font(.system(size: 22))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#1E1E1E"))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2A2A2A"), lineWidth: 1))
                        Text(slotType.rawValue)
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12)).foregroundColor(Color(hex: "#444444"))
                    }
                    .padding(14)
                    .background(Color(hex: "#1A1A1A")).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#242424"), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 200
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

#Preview { DashboardView().preferredColorScheme(.dark) }
