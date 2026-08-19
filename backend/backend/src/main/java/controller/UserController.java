package backend.controller;

import backend.entity.UserInfo;
import backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*") // This allows your frontend to send requests to the backend without being blocked
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/login")
    public String saveUser(@RequestBody UserInfo userInfo) {
        // This takes the data from your frontend and saves it to Postgres!
        userRepository.save(userInfo);
        return "User info saved successfully!";
    }
}