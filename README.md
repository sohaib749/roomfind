# roomfind

Here's a comprehensive **README.md** file for your hotel booking app project that explains all the key features and functionality:

```markdown
# RoomFind - Hotel Booking Application



RoomFind is a Flutter-based hotel booking application that allows users to discover and book hotel rooms both online and offline. The app features a dual booking system, real-time availability checks, and an intuitive user interface.

## Key Features

### 1. Dual Booking System
- **Online Booking**: Customers can book rooms directly through the app
- **Offline Booking**: Hotel staff can manage bookings on behalf of customers

### 2. Room Management
- View room details (type, price, amenities)
- See high-quality images of each room
- Check real-time availability

### 3. Booking Features
- Interactive calendar for date selection
- Range selection (check-in to check-out dates)
- Automatic conflict detection for double bookings
- Booking confirmation with details

### 4. User Experience
- Hotel search by city
- Room filtering options
- Responsive design for all screen sizes
- Image gallery with zoom functionality

## Technical Architecture

### Backend
- **Firebase Firestore**: Real-time database for rooms and bookings
- **Cloudinary**: Hosting for room images

### Frontend
- **Flutter**: Cross-platform framework
- **State Management**: Provider pattern
- **Key Packages**:
  - `table_calendar`: For interactive date selection
  - `intl`: For date formatting
  - `cloud_firestore`: Firebase integration

## Document Structure

### Rooms Collection
```json
{
  "amenities": ["TV", "WIFI", "AC"],
  "hotelId": "vaw8qIswGY8KptyLEGuQ",
  "imageUrls": ["https://...", "https://..."],
  "price": 1000,
  "roomNumber": "101",
  "status": "Available",
  "type": "Deluxe"
}
```

### Bookings Collection
```json
{
  "roomId": "room123",
  "roomNumber": "101",
  "hotelId": "hotel456",
  "startDate": "2023-11-15",
  "endDate": "2023-11-20",
  "guestName": "John Doe",
  "guestEmail": "john@example.com",
  "bookingType": "Online",
  "status": "Confirmed",
  "paymentMethod": "Credit Card"
}
```






## Future Enhancements
- [ ] Booking is under development
- [ ]Advanced Query Architecture
- [ ] Real-time Efficiency Improvements
- [ ] Payment gateway integration
- [ ] User reviews and ratings
- [ ] Loyalty program
- [ ] Push notifications for booking updates




