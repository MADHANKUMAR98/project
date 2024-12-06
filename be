To create a robust electricity billing system that incorporates all the use cases and advanced functionality, I'll outline the steps to include features like:

1. **Admin and Customer Roles**
2. **Spring Security** for role-based authentication and authorization
3. **Basic CRUD operations** (add customer, generate bills, make payments)
4. **Advanced Use Cases** like pending payments, bill history, and detailed customer management
5. **Separation of concerns** by using distinct POJO, Entity, DAO, Service, and Controller layers.
6. **Spring Boot Architecture** with service layers and REST endpoints.
7. **Database schema** with SQL scripts for the required entities.

### Project Structure

```
src/
└── main/
    ├── java/
    │   └── com/
    │       └── example/
    │           └── ebs/
    │               ├── config/           // Spring Security Config
    │               ├── controller/       // REST Controllers
    │               ├── dao/              // DAO interfaces
    │               ├── entity/           // JPA Entities
    │               ├── pojo/             // Data Transfer Objects (DTOs)
    │               ├── service/          // Service Layer
    │               ├── util/             // Utility classes
    └── resources/
        ├── application.properties
        ├── data.sql                     // Predefined database values
        ├── schema.sql                   // SQL scripts for table creation
```

---

### 1. **Spring Security Configuration**

We'll need to secure our application with role-based access for admin and customer. Here’s how we’ll configure Spring Security:

#### `SecurityConfig.java`

```java
package com.example.ebs.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeHttpRequests((requests) -> requests
                .antMatchers("/admin/**").hasRole("ADMIN")
                .antMatchers("/customer/**").hasRole("CUSTOMER")
                .anyRequest().authenticated()
            )
            .formLogin().permitAll()
            .and()
            .logout().permitAll();

        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails admin = User.withDefaultPasswordEncoder()
            .username("admin1")
            .password("1234")
            .roles("ADMIN")
            .build();

        UserDetails customer = User.withDefaultPasswordEncoder()
            .username("customer1")
            .password("password")
            .roles("CUSTOMER")
            .build();

        return new InMemoryUserDetailsManager(admin, customer);
    }
}
```

---

### 2. **Entity Classes**

#### `CustomerEntity.java`

```java
package com.example.ebs.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Entity
@Table(name = "EBS_customer")
public class CustomerEntity {

    @Id
    @Column(name = "customer_id")
    private String customerId;

    @Column(name = "customer_name")
    private String customerName;

    @Column(name = "contact_number")
    private String contactNumber;

    @Column(name = "email")
    private String email;

    @Embedded
    private AddressEntity address;

    @OneToMany(mappedBy = "customerEntity", cascade = CascadeType.ALL)
    private List<BillEntity> bills;
}
```

#### `AddressEntity.java`

```java
package com.example.ebs.entity;

import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Embeddable
public class AddressEntity {
    private String houseNumber;
    private String streetName;
    private String areaName;
    private String city;
    private String state;
    private String pincode;
}
```

#### `BillEntity.java`

```java
package com.example.ebs.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Entity
@Table(name = "EBS_bill")
public class BillEntity {

    @Id
    @Column(name = "bill_id")
    private String billId;

    @ManyToOne
    @JoinColumn(name = "customer_id")
    private CustomerEntity customerEntity;

    @Column(name = "electricity_used")
    private double electricityUsed;

    @Column(name = "bill_amount")
    private double billAmount;

    @Column(name = "bill_date")
    private String billDate;

    @Column(name = "due_date")
    private String dueDate;

    @Column(name = "is_paid")
    private boolean isPaid;
}
```

#### `PaymentEntity.java`

```java
package com.example.ebs.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Entity
@Table(name = "EBS_payment")
public class PaymentEntity {

    @Id
    @Column(name = "payment_id")
    private String paymentId;

    @ManyToOne
    @JoinColumn(name = "customer_id")
    private CustomerEntity customerEntity;

    @ManyToOne
    @JoinColumn(name = "bill_id")
    private BillEntity billEntity;

    @Column(name = "payment_date")
    private String paymentDate;

    @Column(name = "payment_method")
    private String paymentMethod;

    @Column(name = "amount_paid")
    private double amountPaid;
}
```

---

### 3. **DAO Layer (Repository Interfaces)**

#### `CustomerRepository.java`

```java
package com.example.ebs.dao;

import com.example.ebs.entity.CustomerEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerRepository extends JpaRepository<CustomerEntity, String> {
}
```

#### `BillRepository.java`

```java
package com.example.ebs.dao;

import com.example.ebs.entity.BillEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BillRepository extends JpaRepository<BillEntity, String> {
}
```

#### `PaymentRepository.java`

```java
package com.example.ebs.dao;

import com.example.ebs.entity.PaymentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PaymentRepository extends JpaRepository<PaymentEntity, String> {
}
```

---

### 4. **Service Layer**

#### `CustomerService.java`

```java
package com.example.ebs.service;

import com.example.ebs.dao.CustomerRepository;
import com.example.ebs.entity.CustomerEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CustomerService {

    @Autowired
    private CustomerRepository customerRepository;

    public List<CustomerEntity> getAllCustomers() {
        return customerRepository.findAll();
    }

    public CustomerEntity addCustomer(CustomerEntity customer) {
        return customerRepository.save(customer);
    }

    public Optional<CustomerEntity> findCustomerById(String customerId) {
        return customerRepository.findById(customerId);
    }

    public void deleteCustomer(String customerId) {
        customerRepository.deleteById(customerId);
    }
}
```

#### `BillService.java`

```java
package com.example.ebs.service;

import com.example.ebs.dao.BillRepository;
import com.example.ebs.entity.BillEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BillService {

    @Autowired
    private BillRepository billRepository;

    public List<BillEntity> getAllBills() {
        return billRepository.findAll();
    }

    public BillEntity addBill(BillEntity bill) {
        return billRepository.save(bill);
    }
}
```

#### `PaymentService.java`

```java
package com.example.ebs.service;

import com.example.ebs.dao.PaymentRepository;
import com.example.ebs.entity.PaymentEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PaymentService {

    @Autowired
    private PaymentRepository paymentRepository;

    public List<PaymentEntity> getAllPayments() {
        return paymentRepository.findAll();
    }

    public PaymentEntity addPayment(PaymentEntity payment) {
        return paymentRepository.save(payment);
    }
}
```

---

### 5. **Controller Layer**

#### `CustomerController.java`

```java
package com.example.ebs.controller;

import com.example.ebs.entity.CustomerEntity;
import com.example.ebs.service.CustomerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/admin/customers")
public class CustomerController {

    @Autowired
    private CustomerService customerService;

    @GetMapping
    public List<CustomerEntity> getAllCustomers() {
        return customerService.getAllCustomers();
    }

    @PostMapping
    public CustomerEntity addCustomer(@RequestBody CustomerEntity customer) {
        return customerService.addCustomer(customer);
    }

    @GetMapping("/{id}")
    public Optional<CustomerEntity> getCustomerById(@PathVariable

    ```java
    String id) {
        return customerService.findCustomerById(id);
    }

    @DeleteMapping("/{id}")
    public void deleteCustomer(@PathVariable String id) {
        customerService.deleteCustomer(id);
    }
}
```

#### `BillController.java`

```java
package com.example.ebs.controller;

import com.example.ebs.entity.BillEntity;
import com.example.ebs.service.BillService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/bills")
public class BillController {

    @Autowired
    private BillService billService;

    @GetMapping
    public List<BillEntity> getAllBills() {
        return billService.getAllBills();
    }

    @PostMapping
    public BillEntity addBill(@RequestBody BillEntity bill) {
        return billService.addBill(bill);
    }

    @GetMapping("/{id}")
    public BillEntity getBillById(@PathVariable String id) {
        return billService.getAllBills().stream()
            .filter(b -> b.getBillId().equals(id))
            .findFirst()
            .orElse(null);
    }
}
```

#### `PaymentController.java`

```java
package com.example.ebs.controller;

import com.example.ebs.entity.PaymentEntity;
import com.example.ebs.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/customer/payments")
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    @GetMapping
    public List<PaymentEntity> getAllPayments() {
        return paymentService.getAllPayments();
    }

    @PostMapping
    public PaymentEntity addPayment(@RequestBody PaymentEntity payment) {
        return paymentService.addPayment(payment);
    }

    @GetMapping("/{id}")
    public PaymentEntity getPaymentById(@PathVariable String id) {
        return paymentService.getAllPayments().stream()
            .filter(p -> p.getPaymentId().equals(id))
            .findFirst()
            .orElse(null);
    }
}
```

---

### 6. **Utility for UUID Generation**

To generate a 6-character UUID for `CustomerId`, we can use a utility class:

```java
package com.example.ebs.util;

import java.util.UUID;

public class UUIDGenerator {

    public static String generateUUID() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 6);
    }
}
```

---

### 7. **POJO Classes**

#### `CustomerPojo.java`

```java
package com.example.ebs.pojo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
public class CustomerPojo {
    private String customerId;
    private String customerName;
    private String contactNumber;
    private String email;
    private AddressPojo address;
}
```

#### `AddressPojo.java`

```java
package com.example.ebs.pojo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
public class AddressPojo {
    private String houseNumber;
    private String streetName;
    private String areaName;
    private String city;
    private String state;
    private String pincode;
}
```

#### `BillPojo.java`

```java
package com.example.ebs.pojo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
public class BillPojo {
    private String billId;
    private String customerId;
    private double electricityUsed;
    private double billAmount;
    private String billDate;
    private String dueDate;
    private boolean isPaid;
}
```

---

### 8. **SQL Scripts**

In the `resources/schema.sql`:

```sql
CREATE TABLE EBS_customer (
    customer_id VARCHAR(6) PRIMARY KEY,
    customer_name VARCHAR(50),
    contact_number VARCHAR(15),
    email VARCHAR(50),
    house_number VARCHAR(20),
    street_name VARCHAR(50),
    area_name VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    pincode VARCHAR(10)
);

CREATE TABLE EBS_bill (
    bill_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(6),
    electricity_used DOUBLE,
    bill_amount DOUBLE,
    bill_date VARCHAR(20),
    due_date VARCHAR(20),
    is_paid BOOLEAN,
    FOREIGN KEY (customer_id) REFERENCES EBS_customer(customer_id)
);

CREATE TABLE EBS_payment (
    payment_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(6),
    bill_id VARCHAR(10),
    payment_date VARCHAR(20),
    payment_method VARCHAR(20),
    amount_paid DOUBLE,
    FOREIGN KEY (customer_id) REFERENCES EBS_customer(customer_id),
    FOREIGN KEY (bill_id) REFERENCES EBS_bill(bill_id)
);
```

---

### 9. **Final Configuration (application.properties)**

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/ebs_db
spring.datasource.username=root
spring.datasource.password=password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.datasource.initialization-mode=always
```

---

### Conclusion

This structure includes Spring Security for role-based authentication, a well-layered architecture, and the necessary features for the electricity billing system. You can further extend it by integrating advanced security features, error handling, and optimizations based on specific requirements.



To achieve a clean separation of concerns in the electricity billing system, we will divide the application into two controllers: one for `Admin` and one for `Customer`, with role-based access control using Spring Security. The structure will ensure that both roles can interact with the system but have access to only their respective use cases.

### Application Structure:
```bash
src/
└── main/
    ├── java/
    │   └── com/
    │       └── example/
    │           └── ebs/
    │               ├── controller/
    │               │   ├── AdminController.java
    │               │   ├── CustomerController.java
    │               ├── dao/
    │               │   ├── CustomerRepository.java
    │               │   ├── BillRepository.java
    │               │   ├── PaymentRepository.java
    │               ├── entity/
    │               │   ├── CustomerEntity.java
    │               │   ├── BillEntity.java
    │               │   ├── PaymentEntity.java
    │               ├── pojo/
    │               │   ├── CustomerPojo.java
    │               │   ├── BillPojo.java
    │               │   ├── PaymentPojo.java
    │               ├── service/
    │               │   ├── CustomerService.java
    │               │   ├── AdminService.java
    │               ├── exception/
    │               └── config/
    │                   └── SecurityConfig.java
    └── resources/
        ├── application.properties
        └── schema.sql
```

### 1. **Controller Layer**

#### `AdminController.java`

```java
package com.example.ebs.controller;

import com.example.ebs.entity.CustomerEntity;
import com.example.ebs.entity.BillEntity;
import com.example.ebs.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private AdminService adminService;

    // Manage Customers
    @PostMapping("/customers")
    public CustomerEntity addCustomer(@RequestBody CustomerEntity customer) {
        return adminService.addCustomer(customer);
    }

    @GetMapping("/customers")
    public List<CustomerEntity> getAllCustomers() {
        return adminService.getAllCustomers();
    }

    @GetMapping("/customers/{id}")
    public CustomerEntity getCustomerById(@PathVariable String id) {
        return adminService.findCustomerById(id);
    }

    @PutMapping("/customers/{id}")
    public CustomerEntity updateCustomer(@PathVariable String id, @RequestBody CustomerEntity customer) {
        return adminService.updateCustomer(id, customer);
    }

    @DeleteMapping("/customers/{id}")
    public void deleteCustomer(@PathVariable String id) {
        adminService.deleteCustomer(id);
    }

    // Manage Bills
    @PostMapping("/bills")
    public BillEntity addBill(@RequestBody BillEntity bill) {
        return adminService.addBill(bill);
    }

    @GetMapping("/bills")
    public List<BillEntity> getAllBills() {
        return adminService.getAllBills();
    }

    @GetMapping("/bills/{id}")
    public BillEntity getBillById(@PathVariable String id) {
        return adminService.getBillById(id);
    }

    // View Payments
    @GetMapping("/payments")
    public List<PaymentEntity> getAllPayments() {
        return adminService.getAllPayments();
    }
}
```

#### `CustomerController.java`

```java
package com.example.ebs.controller;

import com.example.ebs.entity.BillEntity;
import com.example.ebs.entity.PaymentEntity;
import com.example.ebs.service.CustomerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/customer")
public class CustomerController {

    @Autowired
    private CustomerService customerService;

    // View Bills
    @GetMapping("/bills")
    public List<BillEntity> getBills() {
        return customerService.getAllBills();
    }

    @GetMapping("/bills/{id}")
    public BillEntity getBillById(@PathVariable String id) {
        return customerService.getBillById(id);
    }

    // Make Payment
    @PostMapping("/payments")
    public PaymentEntity makePayment(@RequestBody PaymentEntity payment) {
        return customerService.makePayment(payment);
    }

    @GetMapping("/payments")
    public List<PaymentEntity> getPayments() {
        return customerService.getAllPayments();
    }
}
```

### 2. **Service Layer**

#### `AdminService.java`

```java
package com.example.ebs.service;

import com.example.ebs.dao.CustomerRepository;
import com.example.ebs.dao.BillRepository;
import com.example.ebs.dao.PaymentRepository;
import com.example.ebs.entity.CustomerEntity;
import com.example.ebs.entity.BillEntity;
import com.example.ebs.entity.PaymentEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AdminService {

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private BillRepository billRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    // Customer management
    public CustomerEntity addCustomer(CustomerEntity customer) {
        return customerRepository.save(customer);
    }

    public List<CustomerEntity> getAllCustomers() {
        return customerRepository.findAll();
    }

    public CustomerEntity findCustomerById(String id) {
        return customerRepository.findById(id).orElse(null);
    }

    public CustomerEntity updateCustomer(String id, CustomerEntity updatedCustomer) {
        CustomerEntity existingCustomer = findCustomerById(id);
        if (existingCustomer != null) {
            existingCustomer.setCustomerName(updatedCustomer.getCustomerName());
            existingCustomer.setContactNumber(updatedCustomer.getContactNumber());
            existingCustomer.setAddress(updatedCustomer.getAddress());
            return customerRepository.save(existingCustomer);
        }
        return null;
    }

    public void deleteCustomer(String id) {
        customerRepository.deleteById(id);
    }

    // Bill management
    public BillEntity addBill(BillEntity bill) {
        return billRepository.save(bill);
    }

    public List<BillEntity> getAllBills() {
        return billRepository.findAll();
    }

    public BillEntity getBillById(String id) {
        return billRepository.findById(id).orElse(null);
    }

    // Payments
    public List<PaymentEntity> getAllPayments() {
        return paymentRepository.findAll();
    }
}
```

#### `CustomerService.java`

```java
package com.example.ebs.service;

import com.example.ebs.dao.BillRepository;
import com.example.ebs.dao.PaymentRepository;
import com.example.ebs.entity.BillEntity;
import com.example.ebs.entity.PaymentEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CustomerService {

    @Autowired
    private BillRepository billRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    public List<BillEntity> getAllBills() {
        return billRepository.findAll();
    }

    public BillEntity getBillById(String id) {
        return billRepository.findById(id).orElse(null);
    }

    public PaymentEntity makePayment(PaymentEntity payment) {
        return paymentRepository.save(payment);
    }

    public List<PaymentEntity> getAllPayments() {
        return paymentRepository.findAll();
    }
}
```

### 3. **Security Configuration**

To handle role-based access, we'll use Spring Security. The `SecurityConfig.java` will define the role-based access control for the admin and customer endpoints.

#### `SecurityConfig.java`

```java
package com.example.ebs.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.csrf().disable()
                .authorizeRequests()
                .antMatchers("/admin/**").hasRole("ADMIN")
                .antMatchers("/customer/**").hasRole("CUSTOMER")
                .anyRequest().authenticated()
                .and()
                .formLogin()
                .and()
                .httpBasic();
        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails admin = User.withDefaultPasswordEncoder()
                .username("admin")
                .password("admin123")
                .roles("ADMIN")
                .build();

        UserDetails customer = User.withDefaultPasswordEncoder()
                .username("customer")
                .password("customer123")
                .roles("CUSTOMER")
                .build();

        return new InMemoryUserDetailsManager(admin, customer);
    }
}
```

### 4. **Entity and Repository Classes**

#### `CustomerEntity.java`

```java
package com.example.ebs.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "EBS_customer")
public class CustomerEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private String customerId;
    private String customerName;
    private String contactNumber

    Continuing with the `CustomerEntity.java` and other essential entities for the electricity billing system:

#### `CustomerEntity.java`

```java
package com.example.ebs.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.util.List;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "EBS_customer")
public class CustomerEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private String customerId;
    
    @Column(name = "customer_name", nullable = false)
    private String customerName;

    @Column(name = "contact_number", nullable = false)
    private String contactNumber;

    @OneToMany(mappedBy = "customerEntity", cascade = CascadeType.ALL)
    private List<BillEntity> bills;

    @OneToMany(mappedBy = "customerEntity", cascade = CascadeType.ALL)
    private List<PaymentEntity> payments;

    @Embedded
    private Address address;
}
```

#### `BillEntity.java`

```java
package com.example.ebs.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "EBS_bill")
public class BillEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private String billId;

    @Column(name = "amount", nullable = false)
    private Double amount;

    @Column(name = "units_consumed", nullable = false)
    private Integer unitsConsumed;

    @Column(name = "bill_date", nullable = false)
    private LocalDateTime billDate;

    @ManyToOne
    @JoinColumn(name = "customer_id", nullable = false)
    private CustomerEntity customerEntity;
}
```

#### `PaymentEntity.java`

```java
package com.example.ebs.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "EBS_payment")
public class PaymentEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private String paymentId;

    @Column(name = "payment_amount", nullable = false)
    private Double paymentAmount;

    @Column(name = "payment_method", nullable = false)
    private String paymentMethod; // e.g., Credit Card, Debit Card, etc.

    @Column(name = "payment_timestamp", nullable = false)
    private LocalDateTime paymentTimestamp;

    @ManyToOne
    @JoinColumn(name = "customer_id", nullable = false)
    private CustomerEntity customerEntity;
}
```

#### `Address.java`

```java
package com.example.ebs.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.Embeddable;

@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Address {

    @Column(name = "house_number")
    private String houseNumber;

    @Column(name = "street_name")
    private String streetName;

    @Column(name = "area_name")
    private String areaName;

    @Column(name = "city")
    private String city;

    @Column(name = "state")
    private String state;

    @Column(name = "pincode")
    private String pincode;
}
```

### 5. **Repository Layer**

#### `CustomerRepository.java`

```java
package com.example.ebs.dao;

import com.example.ebs.entity.CustomerEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CustomerRepository extends JpaRepository<CustomerEntity, String> {
}
```

#### `BillRepository.java`

```java
package com.example.ebs.dao;

import com.example.ebs.entity.BillEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BillRepository extends JpaRepository<BillEntity, String> {
}
```

#### `PaymentRepository.java`

```java
package com.example.ebs.dao;

import com.example.ebs.entity.PaymentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PaymentRepository extends JpaRepository<PaymentEntity, String> {
}
```

### 6. **Spring Boot Application Class**

#### `EBSApplication.java`

```java
package com.example.ebs;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class EBSApplication {

    public static void main(String[] args) {
        SpringApplication.run(EBSApplication.class, args);
    }
}
```

### 7. **Database Schema (schema.sql)**

You can add the necessary schema to create the database tables, or Spring Boot will automatically generate them using the `@Entity` annotations.

### 8. **`application.properties`**

```properties
spring.datasource.url=jdbc:oracle:thin:@localhost:1521:xe
spring.datasource.username=your_db_username
spring.datasource.password=your_db_password
spring.datasource.driver-class-name=oracle.jdbc.OracleDriver
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.Oracle12cDialect
```

---

This complete structure divides the use cases into `Admin` and `Customer` roles, with separate services for handling operations, security configuration for role-based access, and a clean entity design. Additionally, Spring Security provides protection by ensuring only the respective roles can access their endpoints.
