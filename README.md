# E-Commerce App

This e-commerce app was developed by **:**
**$${\color{darkslateblue}Fady}  {\color{teal}Gerges}  {\color{olive}Kodsy}  {\color{cadetblue}Al}  {\color{darkseagreen}Sagheer}$$**

## Table of Contents
1. [Features](#features)
   - [Splash Screen](#splash-screen)
   - [Onboarding Screens](#onboarding-screens)
   - [Welcome Screen](#welcome-screen)
   - [Login and Signup](#login-and-signup)
   - [Home Page (Discover)](#home-page-discover)
   - [Add to Cart](#add-to-cart)
   - [Add to Favorites](#add-to-favorites)
   - [Dark Mode](#dark-mode)
   - [Search Functionality](#search-functionality)
   - [Product Details Page](#product-details-page)
   - [Comments Section](#comments-section)
   - [Filters](#filters)
   - [Account Settings](#account-settings)
   - [About Us](#about-us)
2. [Technologies Used](#technologies-used)
3. [Installation](#installation)

## Features

### Splash Screen
- The app includes a splash screen with an icon representing the app.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Splash%20Screen.png" alt="Splash Screen" width="300"/>

### Onboarding Screens
- The onboarding screens appear when the user opens the app for the first time.
- They provide details about the e-commerce store, including its top-notch security.
- After completing the onboarding process, it won't reappear, and the user is directed to the Welcome Screen.

<div style="display: flex; justify-content: space-around;">
    <img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Onboarding%20Screen1.png" alt="Onboarding Screen 1" width="300"/>
    <img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Onboarding%20Screen2.png" alt="Onboarding Screen 2" width="300"/>
    <img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Onboarding%20Screen3.png" alt="Onboarding Screen 3" width="300"/>
</div>

### Welcome Screen
- The Welcome Screen provides options to log in, sign up, or log in as a guest.
- It serves as the entry point after the onboarding process is complete.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Welcome%20Screen.png" alt="Welcome Screen" width="300"/>

### Login and Signup
- Users can either log in or sign up for a new account.
- The signup process allows users to upload a profile picture, and enter their name, email, and password.
- An alternative method is signing up using a Google account.
<div style="display: flex; justify-content: space-around;">
<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Login%20.png" alt="Login" width="300"/>
<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Signup.png" alt="Signup" width="300"/>
</div>

### Home Page (Discover)
- The home page displays a carousel showcasing different categories like beauty, fragrances, furniture, and groceries.
- Users can browse items within a specific category and view details, including the old and new prices of products.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Home.png" alt="Home" width="300"/>

### Add to Cart
- Products can be added to the shopping cart, and users can adjust the quantity.
- The app shows available stock, and users can't add more items than the stock allows.
- Once the stock runs out, the product is marked as "Out of Stock" in real-time.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Cart%20Page.png" alt="Cart Page" width="300"/>

### Add to Favorites
- Users can add or remove items from their favorites list, with the old and new prices displayed.
- The favorites list is dynamically updated.
- Each user's favorite products are linked with their email in Firebase, ensuring that each customer has their list of favorite products.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Favorites%20Page.png" alt="Favorites Page" width="300"/>

### Dark Mode
- The app supports Dark Mode for a more comfortable viewing experience, reducing eye strain.
- Users can toggle between Dark Mode and Light Mode.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Dark%20mode.png" alt="Dark Mode" width="300"/>

### Search Functionality
- The search bar provides real-time suggestions while typing and shows product ratings and comments.
- Users can search for specific items using keywords.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Search%20Page.png" alt="Search Page" width="300"/>

### Product Details Page
- The Products Page includes detailed information about each product, including images, descriptions, and pricing.
- Users can view comments and replies related to the product.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Products%20Page.png" alt="Products Page" width="300"/>

### Comments Section
- Users can leave comments on products.
- Others can reply to comments, creating a discussion around each product.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Comments%20and%20Reply%20Section.png" alt="Comments and Reply Section" width="300"/>

### Filters
- The filter button allows users to sort and filter products by different criteria.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Filter.png" alt="Filters Page" width="300"/> <!-- Assuming the Filters Page image is the same as the Products Page -->

### Account Settings
- Users can update their profile picture, username, and password.
- The app supports multiple languages, including English, Arabic, French, and Spanish.

<img src="https://github.com/Fady2024/Ecommerce-app/blob/main/App%20Photos/Account%20page.png" alt="Account Page" width="300"/>

### About Us
- The app provides details about the developers.

<!-- Add image if available -->

## Technologies Used
- **Flutter**: For building the app.
- **Bloc State Management**: To manage app state.
- **Firebase**: This is for backend services.
- **Google Sign-In API**: For authentication.

## Installation

1. Clone the repository: `git clone https://github.com/Fady2024/Ecommerce-app.git`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Library Used
The **DayNightSwitch** library (Copyright (c) 2022 Divyanshu Bhargava) was used in the development of this application, providing the feature to toggle between light and dark modes. You can view the code and more details [here](https://github.com/DivyanshuBhargava/DayNightSwitch).
