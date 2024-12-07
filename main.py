import requests
#import os
from datetime import datetime

api_key = '87d845b0b6cf29baa1a73cc34b067a95'
location = input("Enter the city name: ")

complete_api_link = "https://api.openweathermap.org/data/2.5/weather?q="+location+"&appid="+api_key
api_link = requests.get(complete_api_link)
api_data = api_link.json()

#create variables to store and display data
temp_city = ((api_data['main']['temp']) - 273.15)
weather_desc = api_data['weather'][0]['description']
hmdt = api_data['main']['humidity']
wind_spd = api_data['wind']['speed']
date_time = datetime.now().strftime("%d %b %Y | %I:%M:%S %p")

print ("-------------------------------------------------------------")
print ("Weather Stats for - {}  || {}".format(location.upper(), date_time))
print ("-------------------------------------------------------------")

print ("Current temperature is: {:.2f} deg C".format(temp_city))
print ("Current weather desc  :",weather_desc)
print ("Current Humidity      :",hmdt, '%')
print ("Current wind speed    :",wind_spd ,'kmph')
The **front-end components** for a project depend on its scope and purpose. For a typical **electricity billing system** or a similar project, here’s a list of front-end components you might implement:

---

### **1. Login and Registration**
- **Login Page:**
  - Fields: Username, Password.
  - Button: "Login".
  - Features: Validation for empty fields, password masking.
- **Registration Page (Admin/Customer):**
  - Fields: Name, Email, Password, Confirm Password, Contact Number, Address.
  - Dropdown for Role: Admin/Customer.
  - Button: "Register".
  - Features: Validation for email, password strength, and field completion.

---

### **2. Dashboard**
- **Admin Dashboard:**
  - Navigation Menu: Links to manage customers, generate bills, view payments, and pending bills.
  - Widgets: Summary cards for total customers, bills generated, and payments pending.
  - Charts: Payment history trends, electricity usage statistics.
- **Customer Dashboard:**
  - Navigation Menu: Links to view bills, make payments, and check consumption history.
  - Widgets: Quick overview of pending payments, total consumption, and payment history.

---

### **3. Customer Management (Admin)**
- **Customer List Page:**
  - Table: Displays customer details (Name, Email, Contact, Address, Status).
  - Actions: Edit, Delete buttons for each customer.
- **Add/Edit Customer Form:**
  - Fields: Name, Email, Contact Number, Address (Detailed address fields like House No., Street, City, etc.).
  - Buttons: "Save", "Cancel".

---

### **4. Bill Management**
- **Bill Generation (Admin):**
  - Form: Fields to input Customer ID, Month, Units Consumed.
  - Buttons: "Generate Bill", "Cancel".
  - Output: Displays generated bill details.
- **View Bills (Customer):**
  - Table: Lists previous bills with columns for Date, Units Consumed, Amount, Status (Paid/Unpaid).
  - Filters: Search by month/year, filter by status.
- **Pending Bills (Admin):**
  - Table: Displays unpaid bills with Customer ID, Amount Due, Due Date.

---

### **5. Payment Management**
- **Make Payment (Customer):**
  - Fields: Payment Method (Dropdown: Credit Card, Debit Card, UPI, etc.), Amount.
  - Buttons: "Pay Now", "Cancel".
  - Output: Displays payment confirmation.
- **Payment History (Customer):**
  - Table: Lists previous payments with Date, Amount, Method, and Transaction ID.
- **View Payments (Admin):**
  - Table: Displays all payments with filters for Customer ID, Date Range.

---

### **6. Reports and Analytics (Admin)**
- **Consumption Report:**
  - Charts: Bar/Line graphs showing monthly consumption for each customer.
- **Payment Status:**
  - Pie chart: Paid vs Unpaid bills.
- **Usage Trends:**
  - Line chart: Electricity usage over months for a specific customer.

---

### **7. Profile and Settings**
- **Profile Page:**
  - Fields: Name, Email, Contact Number, Address.
  - Button: "Edit Profile".
- **Settings Page:**
  - Change Password Form: Old Password, New Password, Confirm Password.
  - Preferences: Options to enable/disable notifications.

---

### **8. Notifications**
- Pop-ups: Alerts for payment due, successful payments, or errors.
- Notification Bell: Displays recent notifications (e.g., “Your bill for October is due.”).

---

### **9. Error Pages**
- **404 Page Not Found:** For invalid routes.
- **500 Internal Server Error:** For backend issues.
- **Form Error Messages:** For validation errors (e.g., “Password must be at least 8 characters.”).

---

### **Technologies and Tools for Front-End**
- **Frameworks/Libraries:**
  - HTML, CSS, JavaScript.
  - Frameworks: React.js, Angular, or Vue.js.
  - CSS Libraries: Bootstrap, Tailwind CSS.
- **Charts and Graphs:**
  - Libraries: Chart.js, D3.js, or ApexCharts.
- **Validation:**
  - Libraries: Formik (React), Vuelidate (Vue.js).

---

### **Responsive Design**
- Ensure the design is mobile-friendly using media queries or frameworks like Bootstrap.

---

Would you like a detailed layout or sample code for any specific component?
