// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Enum for the different user types in the PMS
enum UserType {
    SUPERUSER,
    SUPERUSER2,
    SUPERUSER3,
    HOSPITAL,
    DOCTOR,
    PATIENT
}

// Struct for storing hospital information
struct Hospital {
    bytes32 name;
    bytes32 _address;
    bytes32 contact;
    address wallet;
}

// Struct for storing doctor information
struct Doctor {
    bytes32 name;
    uint256 hospitalId;
    address wallet;
}

// Struct for storing patient information
struct Patient {
    bytes32 name;
    uint256 doctorId;
}

// Struct for storing medical record information
struct MedicalRecord {
    bytes32 diagnosis;
    bytes32 prescription;
    bytes32 notes;
}

import "./console.sol";

// PMS contract
contract PatientManagementSystem {
    // Mapping of hospital IDs to hospital information
    mapping(uint256 => Hospital) public hospitals;

    // Mapping of doctor IDs to doctor information
    mapping(uint256 => Doctor) public doctors;

    // Mapping of patient IDs to patient information
    mapping(uint256 => Patient) public patients;

    // Mapping of medical record IDs to medical record information
    mapping(uint256 => MedicalRecord) public medicalRecords;

    // Array for storing hospital IDs
    uint256[] public hospitalIds;

    // Array for storing doctor IDs
    uint256[] public doctorIds;

    // Array for storing patient IDs
    uint256[] public patientIds;

    // Array for storing medical record IDs
    uint256[] public medicalRecordIds;

    // Mapping of Ethereum addresses to user types
    mapping(address => UserType) public userTypes;

    // Mapping of Ethereum addresses to hospital IDs (for hospitals and doctors)
    mapping(address => uint256) public hospitalIdsForAddresses;

    // Mapping of Ethereum addresses to doctor IDs (for patients)
    mapping(address => uint256) public doctorIdsForAddresses;

    // Counter for generating unique IDs
    uint256 public patientIdCounter;
    uint256 public hospitalIdCounter;
    uint256 public doctorIdCounter;
    uint256 public medicalIdCounter;

    // Event for logging new hospital registration
    event NewHospitalRegistered(uint256 hospitalId, bytes32 hospitalName);

    // Event for logging new doctor registration
    event NewDoctorRegistered(
        uint256 doctorId,
        bytes32 doctorName,
        uint256 hospitalId,
        address wallet
    );

    // Event for logging new patient registration
    event NewPatientRegistered(
        uint256 patientId,
        bytes32 patientName,
        uint256 doctorId
    );

    // Event for logging new medical record added
    event NewMedicalRecordAdded(
        uint256 medicalRecordId,
        bytes32 diagnosis,
        bytes32 prescription,
        bytes32 notes
    );

    // Constructor function for initializing the contract
    constructor() {
        // Add the contract owner as the initial hospital
        addHospital("Hospital 1", "Address 1", "Contact 1", 0xdD870fA1b7C4700F2BD7f44238821C26f7392148);

        // Set the contract owner as the initial superuser
        userTypes[msg.sender] = UserType.SUPERUSER;
        // hospitalIdsForAddresses[msg.sender] = 0;
    }
    // Function to register a new hospital
    function addHospital(
    bytes32 hospitalName,
    bytes32 hospitalAddress,
    bytes32 hospitalContact,
    address hospitalWallet
    ) public {
        // Only superusers are allowed to register hospitals
        require(
            userTypes[msg.sender] == UserType.SUPERUSER || // current superuser
            userTypes[msg.sender] == UserType.SUPERUSER2 || // additional superuser
            userTypes[msg.sender] == UserType.SUPERUSER3,   // additional superuser
            "Only superusers are allowed to register hospitals."
        );

        // Generate a unique ID for the new hospital
        uint256 hospitalId = hospitalIdCounter;
        hospitalIdCounter++;

        // Add the new hospital to the hospitals mapping
        hospitals[hospitalId] = Hospital(
            hospitalName,
            hospitalAddress,
            hospitalContact,
            hospitalWallet
        );

        // Add the hospital ID to the hospitalIds array
        hospitalIds.push(hospitalId);

        // Set the Ethereum address of the hospital to the hospital ID in the userTypes and hospitalIdsForAddresses mappings
        userTypes[hospitalWallet] = UserType.HOSPITAL;
        hospitalIdsForAddresses[hospitalWallet] = hospitalId;

        // Emit the NewHospitalRegistered event
        emit NewHospitalRegistered(hospitalId, hospitalName);
    }

    // Function to register a new doctor
    function addDoctor(bytes32 doctorName, uint256 hospitalId, address wallet) public {
        // Only hospitals are allowed to register doctors
        require(
            userTypes[msg.sender] == UserType.HOSPITAL &&
            hospitalIdsForAddresses[msg.sender] == hospitalId,
            "Only hospitals are allowed to register doctors."
        );

        // Generate a unique ID for the new doctor
        uint256 doctorId = doctorIdCounter;
        doctorIdCounter++;

        // Add the new doctor to the doctors mapping
        doctors[doctorId] = Doctor(doctorName, hospitalId, wallet);

        // Add the doctor ID to the doctorIds array
        doctorIds.push(doctorId);

        // Set the Ethereum address of the doctor to the doctor ID and hospital ID in the userTypes and hospitalIdsForAddresses mappings
        userTypes[wallet] = UserType.DOCTOR;
        hospitalIdsForAddresses[msg.sender] = hospitalId;

        // Emit the NewDoctorRegistered event
        emit NewDoctorRegistered(doctorId, doctorName, hospitalId, wallet);
    }
    // Function to register a new patient
    function addPatient(bytes32 patientName, uint256 doctorId) public {
        // Only doctors are allowed to register patients
        require(
            userTypes[msg.sender] == UserType.DOCTOR &&
            hospitalIdsForAddresses[msg.sender] == doctors[doctorId].hospitalId,
            "Only doctors are allowed to register patients."
        );

        // Generate a unique ID for the new patient
        uint256 patientId = patientIdCounter;
        patientIdCounter++;

        // Add the new patient to the patients mapping
        patients[patientId] = Patient(patientName, doctorId);

        // Add the patient ID to the patientIds array
        patientIds.push(patientId);

        // Set the Ethereum address of the patient to the doctor ID in the userTypes and doctorIdsForAddresses mappings
        userTypes[msg.sender] = UserType.PATIENT;
        doctorIdsForAddresses[msg.sender] = doctorId;

        // Emit the NewPatientRegistered event
        emit NewPatientRegistered(patientId, patientName, doctorId);
    }
    // Function to add a new medical record
    function addMedicalRecord(
        uint256 patientId,
        bytes32 diagnosis,
        bytes32 prescription,
        bytes32 notes
    ) public {
        // Only hospitals and doctors are allowed to add medical records
        require(
            (userTypes[msg.sender] == UserType.SUPERUSER &&
            hospitalIdsForAddresses[msg.sender] == doctors[patients[patientId].doctorId].hospitalId) ||
            (userTypes[msg.sender] == UserType.DOCTOR &&
            hospitalIdsForAddresses[msg.sender] == doctors[patients[patientId].doctorId].hospitalId),
            "Only hospitals and doctors are allowed to add medical records."
        );

        // Generate a unique ID for the new medical record
        uint256 medicalRecordId = medicalIdCounter;
        medicalIdCounter++;

        // Add the new medical record to the medicalRecords mapping
        medicalRecords[medicalRecordId] = MedicalRecord(
            diagnosis,
            prescription,
            notes
        );

        // Add the medical record ID to the medicalRecordIds array
        medicalRecordIds.push(medicalRecordId);

        // Emit the NewMedicalRecordAdded event
        emit NewMedicalRecordAdded(
            medicalRecordId,
            diagnosis,
            prescription,
            notes
        );
    }
    // Function to add a doctor to a hospital
    // function addDoctorToHospital(address doctor, uint256 hospitalId) public {
        // Only superusers are allowed to add doctors to hospitals
        // require(
        //     userTypes[msg.sender] == UserType.SUPERUSER,
        //     "Only superusers are allowed to add doctors to hospitals."
        // );

        // Set the Ethereum address of the doctor to the doctor ID and hospital ID in the userTypes and hospitalIdsForAddresses mappings
    //     userTypes[doctor] = UserType.DOCTOR;
    //     hospitalIdsForAddresses[doctor] = hospitalId;
    // }
    // Set the SUPERUSER2 or SUPERUSER3 constants for a particular address
    function setSuperuser(address _address, UserType _userType) public {
        // Only the current superuser is allowed to set other superusers
        require(
            userTypes[msg.sender] == UserType.SUPERUSER,
            "Only the current superuser is allowed to set other superusers."
        );

        // Set the user type for the specified address
        userTypes[_address] = _userType;
    }

    // Function to get the user type for an Ethereum address
    function getUserType(address user) public view returns (UserType) {
        return userTypes[user];
    }

    // Function to get the hospital ID for an Ethereum address
    function getHospitalId(address user) public view returns (uint256) {
        return hospitalIdsForAddresses[user];
    }

    // Function to get the doctor ID for an Ethereum address
    function getDoctorId(address user) public view returns (uint256) {
        return doctorIdsForAddresses[user];
    }

    // Function to get the information for a hospital
    function getHospitalInfo(uint256 hospitalId) public view returns (
        bytes32 hospitalName,
        bytes32 hospitalAddress,
        bytes32 hospitalContact,
        address hospitalWallet
    ) {
        return (
            hospitals[hospitalId].name,
            hospitals[hospitalId]._address,
            hospitals[hospitalId].contact,
            hospitals[hospitalId].wallet
        );
    }

    // Function to get the information for a doctor
    function getDoctorInfo(uint256 doctorId) public view returns (
        bytes32 doctorName,
        uint256 hospitalId,
        address _wallet
    ) {
        return (
            doctors[doctorId].name,
            doctors[doctorId].hospitalId,
            doctors[doctorId].wallet
        );
    }

    // Function to get the information for a patient
    function getPatientInfo(uint256 patientId) public view returns (
        bytes32 patientName,
        uint256 doctorId
    ) {
        return (
            patients[patientId].name,
            patients[patientId].doctorId
        );
    }

    // Function to get the information for a medical record
    function getMedicalRecordInfo(uint256 medicalRecordId) public view returns (
        bytes32 diagnosis,
        bytes32 prescription,
        bytes32 notes
    ) {
        return (
            medicalRecords[medicalRecordId].diagnosis,
            medicalRecords[medicalRecordId].prescription,
            medicalRecords[medicalRecordId].notes
        );
    }
}