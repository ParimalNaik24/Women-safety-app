package backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "user_info")
public class UserInfo {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String number; 

    // Default constructor (Required by JPA)
    public UserInfo() {
    }

    // Constructor with fields
    public UserInfo(String name, String number) {
        this.name = name;
        this.number = number;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getNumber() {
        return number;
    }

    public void setNumber(String number) {
        this.number = number;
    }
}