# Requirements Document

## Introduction

This feature surfaces the assigned ambulance's license number to users during an active booking and in order history. The `licenseNumber` field already exists in the `partners` Firestore collection. The work involves propagating this value into the order document at booking time and displaying it in two user-facing screens: `UserTrackingPage` (live tracking) and `OrderDetailScreen` (order history).

No new Firestore collections or backend infrastructure changes are required.

---

## Glossary

- **AmbulanceServiceController**: The Flutter/GetX controller responsible for creating ambulance order documents in Firestore.
- **UserTrackingController**: The Flutter/GetX controller that manages reactive state for the live tracking screen, including fetching partner details.
- **UserTrackingPage**: The user-facing screen displayed during an active ambulance booking, showing real-time tracking information.
- **BottomDraggablePanel**: The draggable bottom sheet widget within `UserTrackingPage` that displays driver and vehicle information.
- **OrderDetailScreen**: The user-facing screen that displays the full details of a past or active order.
- **LicenseBadge**: The UI widget that renders the license number with an icon and styled container inside `BottomDraggablePanel`.
- **Order_Document**: A Firestore document in the `orders` collection representing a single ambulance booking.
- **Partner_Document**: A Firestore document in the `partners` collection representing an ambulance service provider.
- **licenseNumber**: A string field on the `Partner_Document` containing the ambulance's official license identifier (e.g., `"DHK-AMB-2024-001"`). May be null or absent for legacy partner records.

---

## Requirements

### Requirement 1: Embed License Number in Order at Booking Time

**User Story:** As a user, I want the license number to be recorded when I book an ambulance, so that it is available for display in my order history without requiring additional data fetches.

#### Acceptance Criteria

1. WHEN a user creates an ambulance booking and the assigned partner's `Partner_Document` contains a non-null `licenseNumber` field, THE `AmbulanceServiceController` SHALL include the `licenseNumber` value in the `Order_Document` written to Firestore.
2. WHEN a user creates an ambulance booking and the assigned partner's `Partner_Document` does not contain a `licenseNumber` field or the field is null, THE `AmbulanceServiceController` SHALL create the `Order_Document` without a `licenseNumber` field.
3. THE `AmbulanceServiceController` SHALL complete order creation regardless of whether the partner's `licenseNumber` is present or absent.
4. IF the `Partner_Document` does not exist in Firestore, THEN THE `AmbulanceServiceController` SHALL abort order creation and display an error message to the user.

---

### Requirement 2: Fetch and Expose License Number in Tracking Controller

**User Story:** As a user, I want the tracking screen to show my ambulance's license number as soon as a partner accepts my booking, so that I can identify the vehicle.

#### Acceptance Criteria

1. WHEN `_fetchPartnerDetails` is called with a non-empty `partnerId` and the corresponding `Partner_Document` contains a `licenseNumber` field, THE `UserTrackingController` SHALL set `partnerLicenseNumber.value` to the string value of that field.
2. WHEN `_fetchPartnerDetails` is called with a non-empty `partnerId` and the corresponding `Partner_Document` does not contain a `licenseNumber` field or the field is null, THE `UserTrackingController` SHALL set `partnerLicenseNumber.value` to null.
3. IF a Firestore error occurs during `_fetchPartnerDetails`, THEN THE `UserTrackingController` SHALL log the error and leave `partnerLicenseNumber.value` unchanged (null).
4. THE `UserTrackingController` SHALL expose `partnerLicenseNumber` as a reactive observable so that dependent UI widgets rebuild automatically when its value changes.

---

### Requirement 3: Display License Number on the Live Tracking Screen

**User Story:** As a user, I want to see the assigned ambulance's license number on the tracking screen, so that I can identify the vehicle when it arrives.

#### Acceptance Criteria

1. WHEN `partnerLicenseNumber.value` is a non-null, non-empty string, THE `BottomDraggablePanel` SHALL render a `LicenseBadge` widget that displays the license number text.
2. WHEN `partnerLicenseNumber.value` is null or an empty string, THE `BottomDraggablePanel` SHALL render no license-related UI element (i.e., collapse to zero height).
3. THE `BottomDraggablePanel` SHALL position the `LicenseBadge` after the driver name and profile image row and before the trip details section.
4. THE `LicenseBadge` SHALL display a badge icon alongside the license number text.

---

### Requirement 4: Display License Number on the Order Detail Screen

**User Story:** As a user, I want to see the ambulance's license number in my order history, so that I have a record of which vehicle was dispatched.

#### Acceptance Criteria

1. WHEN the `Order_Document` passed to `OrderDetailScreen` contains a non-null, non-empty `licenseNumber` field, THE `OrderDetailScreen` SHALL render a detail row displaying the license number alongside a badge icon.
2. WHEN the `Order_Document` passed to `OrderDetailScreen` does not contain a `licenseNumber` field or the field is null or empty, THE `OrderDetailScreen` SHALL omit the license number row entirely from the detail list.
3. THE `OrderDetailScreen` SHALL not throw an exception regardless of whether `licenseNumber` is present or absent in the order data map.

---

### Requirement 5: Graceful Degradation for Legacy Data

**User Story:** As a user viewing an order created before this feature was deployed, I want the app to continue working normally, so that missing license data does not break my experience.

#### Acceptance Criteria

1. WHILE a user is viewing an `Order_Document` that was created before the `licenseNumber` field was introduced, THE `OrderDetailScreen` SHALL display all other available order fields without error.
2. WHILE a user is on the `UserTrackingPage` and the partner's `Partner_Document` does not contain a `licenseNumber` field, THE `UserTrackingPage` SHALL display all other tracking information without error.
3. THE `BottomDraggablePanel` SHALL render correctly and display all non-license information when `partnerLicenseNumber.value` is null.
