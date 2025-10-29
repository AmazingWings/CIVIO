# Service for Society
## Food Waste & Donation Connector iOS App

A beautiful, functional iOS app that connects people with local food banks, homeless shelters, and recycling centers to reduce waste and help the community.

### 🌟 Features

#### ✅ **Core MVP Features Implemented:**
- **📱 User-Friendly Interface**: Clean green-blue environmental color theme
- **🗺️ Interactive Map View**: Google Maps-style interface with custom markers
- **📍 Location Services**: Finds nearby donation centers based on user location
- **📏 Radius Filtering**: Adjustable search radius (2, 5, 10, 15, 25, 50, 100 miles)
- **🔍 Zoom Controls**: Zoom in/out buttons plus "Show USA" for nationwide view
- **🎯 Smart Sorting**: Centers automatically sorted by distance (closest first)
- **❤️ Favorites System**: Save and manage favorite donation centers
- **🏷️ Smart Filtering**: Filter by center type (Food Banks, Shelters, Recycling, Compost)
- **📋 Detailed Information**: Complete center details including hours, contact info, and accepted items
- **🎨 Beautiful UI**: Consistent green-blue theme throughout

#### 🚀 **Future-Ready Features:**
- **🤖 AI Assistant Tab**: Placeholder ready for AI bot integration
- **💾 Persistent Storage**: Favorites are saved locally
- **📱 Native iOS Design**: SwiftUI with modern iOS design patterns

### 🎯 Target Users
- **Donors**: Restaurants, stores, households with excess food
- **Recipients**: People looking for food assistance or recycling options
- **Community Members**: Anyone wanting to contribute to sustainability

### 📱 App Structure


### 🏗️ Technical Details

#### **Built With:**
- **SwiftUI**: Modern declarative UI framework
- **MapKit**: Native iOS maps with custom annotations
- **Core Location**: GPS and location services
- **Combine**: Reactive programming for data flow

#### **Key Components:**

1. **MapView**: 
   - Interactive map with custom markers
   - Real-time location tracking
   - Radius-based filtering
   - Type-based filtering
   - Detailed center information sheets

2. **FavoritesView**:
   - Clean list of saved centers
   - Quick access to center details
   - Distance calculation from user location
   - Empty state with helpful onboarding

3. **LocationManager**:
   - Handles location permissions
   - Real-time location updates
   - Distance calculations

4. **ColorTheme**:
   - Consistent green-blue environmental colors
   - Light/dark mode support
   - Accessible color combinations

### 🎨 Design System

**Color Palette:**
- **Primary Green**: Teal green for food-related features
- **Primary Blue**: Ocean blue for shelter-related features
- **Accent**: Bright teal for recycling centers
- **Success**: Bright green for compost facilities
- **Background**: Subtle green-blue gradient

### 📊 Nationwide Sample Data

The app now includes **30 donation centers** across major US cities:

**🌎 Geographic Coverage:**
- **California**: San Francisco, Los Angeles
- **New York**: New York City, Brooklyn
- **Texas**: Houston
- **Illinois**: Chicago
- **Arizona**: Phoenix
- **Florida**: Miami/South Florida
- **Washington**: Seattle
- **Massachusetts**: Boston
- **Georgia**: Atlanta
- **North Carolina**: Charlotte, Raleigh, Greensboro, Durham, Winston-Salem
-- WE NEED TO GET THIS TO WORK ALL ACROSS THE UNITED STATES

**🏢 Center Types:**
- ** Food Banks** - Major food banks in each region
- ** Homeless Shelters** - Emergency shelters and missions
- ** Recycling Centers** - Community recycling facilities
- ** Compost Facilities** - Organic waste processing

Each location includes:
- Realistic addresses and contact information
- Actual operating hours
- Comprehensive accepted items lists
- Precise GPS coordinates
- Detailed descriptions of services


### 📍 Location Features

- **Automatic Location**: Finds user's current location with smooth animation
- **Manual Search**: Pan the map to explore areas nationwide
- **Radius Control**: Adjust search radius from 2-100 miles for nationwide coverage
- **Zoom Controls**: Dedicated +/- buttons and "Show USA" for easy navigation
- **Smart Sorting**: Results automatically sorted by distance from your location
- **Smart Filtering**: Show only relevant center types
- **Nationwide Coverage**: Find centers from coast to coast, including North Carolina

### 💡 Future Enhancements

The app is structured to easily add:
- **Push Notifications**: Center hours, special events
- **User Accounts**: Personal donation history/ hopurs worked 

### 🔧 Configuration

The app includes:
- **Bundle ID**: `com.serviceforsociety.app`
- **Deployment Target**: iOS 15.0+
- **Location Permission**: "When in Use" for finding nearby centers
- **MapKit**: Native iOS mapping


---

**Built with ❤️ for the community**

This app represents a complete MVP ready for testing and development. The code is clean, well-structured, and follows iOS development best practices.
