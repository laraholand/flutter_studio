# Flutter Studio

Flutter Studio is an innovative Android application that empowers users to develop Flutter applications directly on their mobile handsets. It stands as the world's first application to offer this unique capability, bringing the full power of Flutter development to your Android device.

This project is now open source! We welcome contributions from the community to help make Flutter Studio even better.

This project is a starting point for a Flutter application.

## Installation and Setup

To install and set up Flutter Studio, follow these steps:

**Important Notes:**
*   ** ⚠️Storage for APK Building:** Building an APK locally *only* (using Termux and Flutter Studio) can consume up to 20GB of storage. We highly recommend using GitHub Actions for building your APKs to save local storage.
*   **Installation Requirements:** The initial setup process requires approximately 3-4GB of storage and 2-3GB of internet data. A stable internet connection is crucial.
*   **Early Release:** Flutter Studio is currently in an early release stage and may not be fully featured.
*   **Key Features:** Enjoy core Flutter development capabilities, including hot reload and hot restart, directly on your Android device!

**Steps:**

1.  **Install Termux:** Download and install Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or directly from [GitHub (v0.118.3)](https://github.com/termux/termux-app/releases/tag/v0.118.3).
2.  **Install Flutter Studio:** Install the Flutter Studio application from its [GitHub Release section](https://github.com/laraholand/flutter_studio/releases/tag/).
3.  **Grant Storage Permission:**
    *   Open Termux.
    *   Run the command: `termux-setup-storage`
4.  **Grant Additional Permissions for Flutter Studio:**
    *   Go to **Flutter Studio's** "App Info".
    *   Navigate to "Permissions" -> "Additional Permissions".
    *   Allow all permissions listed there.
    ![Permission Screenshot](assets/screenshots/permission.png)
    *(Note: UI may vary slightly depending on your Android device and version.)*
5.  **Clone and Execute Setup Repository:**
    *   Open Termux.
    *   Clone the setup repository:
        ```bash
        pkg install git -y && git clone https://github.com/laraholand/Flutter_studio_setup chmod +x Flutter_studio_setup/setup.sh
        ```
    *   Execute the setup script:
        ```bash
        ./Flutter_studio_setup/setup.sh
        ```
    *   It automatically download need thing to use flutter studio    
6.  **Verify Setup (Android Security):**
    *   For Android security, it is recommended to open Termux every time after unlocking your phone.
    *   After your phone locks, open and close the Termux application once.
    *   Open Flutter Studio. If you see the Termux icon in your notification panel, the setup is successful.

![Setup Successful Screenshot](assets/screenshots/xyz.jpg)
## Screenshots of Runtime example 

![Screenshot 6](assets/screenshots/6.jpg)
![Screenshot 5](assets/screenshots/5.jpg)
![Screenshot 4](assets/screenshots/4.jpg)
![Screenshot 3](assets/screenshots/3.jpg)
![Screenshot 2](assets/screenshots/2.jpg)
![Screenshot 1](assets/screenshots/1.jpg)
![Screenshot 0](assets/screenshots/0.jpg)

