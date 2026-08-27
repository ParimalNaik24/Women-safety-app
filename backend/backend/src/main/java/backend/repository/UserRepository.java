package backend.repository;

import backend.entity.UserInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<UserInfo, Long> {
    // Spring Data JPA automatically gives us methods like .save(), .findAll(), etc.
    // We don't even have to write the SQL!
}