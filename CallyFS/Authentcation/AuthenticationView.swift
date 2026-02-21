//
//  AuthenticationView.swift
//  CallyFS
//
//  Created by Nishit Vats on 01/02/26.
//

import Foundation
import SwiftUI


struct AuthenticationView : View {
    @State var signInTapped = false
    
    var body: some View {
        ZStack{
            firstScreen
        }
    }
    
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
                        Text("Hellow")
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
}

#Preview {
    AuthenticationView()
}
