pragma solidity ^0.8.15;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/Roles.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

// Enum for the different user types in the PMS
enum UserType { HOSPITAL, DOCTOR, PATIENT }

// Struct for storing hospital information
struct Hospital {
    bytes32 name;
    bytes32 address;
    bytes32 contact;
}

// Struct for storing doctor information
struct Doctor {
    bytes32 name;
    uint hospitalId;
}

// Struct for storing patient information
struct Patient {
    bytes32 name;
    uint doctorId;
}

// Struct for storing medical record information
struct MedicalRecord {
    bytes32 diagnosis;
    bytes32 prescription;
    bytes32 notes;
}

// PMS contract
contract PatientManagementSystem {
    using SafeMath for uint;
    using Roles for bytes32;

    // Mapping of hospital IDs to hospital information
    mapping(uint => Hospital) public hospitals;

    // Mapping of doctor IDs to doctor information
    mapping(uint => Doctor) public doctors;

    // Mapping of patient IDs to patient information
    mapping(uint => Patient) public patients;

    // Mapping of medical record IDs to medical record information
    mapping(uint => MedicalRecord) public medicalRecords;

    // Array for storing hospital IDs
    uint[] public hospitalIds;

    // Array for storing doctor IDs
    uint[] public doctorIds;

    // Array for storing patient IDs
    uint[] public patientIds;

    // Array for storing medical record IDs
    uint[] public medicalRecordIds;

    // Roles library for managing access control
    Roles public roles;

    // Counter for generating unique IDs
    uint public idCounter;

    // Event for logging new hospital registration
    event NewHospitalRegistered(uint hospitalId, bytes32 hospitalName);

    // Event for logging new doctor registration
    event NewDoctorRegistered(uint doctorId, bytes32 doctorName, uint hospitalId);

    // Event for logging new patient registration
    event NewPatientRegistered(uint patientId, bytes32 patientName, uint doctorId);

    // Event for logging new medical record added
    event NewMedicalRecordAdded(uint medicalRecordId, bytes32 diagnosis, bytes32 prescription, bytes32 notes);

    // Constructor function for initializing the contract
    constructor() public {
        // Add the contract owner as the initial hospital
        addHospital("Hospital 1", "Address 1", "Contact 1");

        // Set the contract owner as the initial superuser
        roles.add(bytes32(keccak256("OWNER")), msg.sender);
    }

    // Function to register a new hospital
    function addHospital(bytes32 hospitalName, bytes32 hospitalAddress, bytes32 hospitalContact) public {
    // Only superusers are allowed to register hospitals
    require(roles.isSuperUser(msg.sender), "Only superusers are allowed to register hospitals.");

    // Generate a unique ID for the new hospital
    uint hospitalId = idCounter;
    idCounter = idCounter.add(1);

    // Add the new hospital to the hospitals mapping
    hospitals[hospitalId] = Hospital(hospitalName, hospitalAddress, hospitalContact);

    // Add the hospital ID to the hospitalIds array
    hospitalIds.push(hospitalId);

    // Emit the NewHospitalRegistered event
    emit NewHospitalRegistered(hospitalId, hospitalName);
    }
    
    // Function to register a new doctor
    function addDoctor(bytes32 doctorName, uint hospitalId) public {
        // Only hospitals are allowed to register doctors
        require(roles.isInRole(UserType.HOSPITAL, msg.sender, hospitalId), "Only hospitals are allowed to register doctors.");

        // Generate a unique ID for the new doctor
        uint doctorId = idCounter;
        idCounter = idCounter.add(1);

        // Add the new doctor to the doctors mapping
        doctors[doctorId] = Doctor(doctorName, hospitalId);

        // Add the doctor ID to the doctorIds array
        doctorIds.push(doctorId);

        // Emit the NewDoctorRegistered event
        emit NewDoctorRegistered(doctorId, doctorName, hospitalId);
    }

    // Function to register a new patient
    function addPatient(bytes32 patientName, uint doctorId) public {
        // Only doctors are allowed to register patients
        require(roles.isInRole(UserType.DOCTOR, msg.sender, doctorId), "Only doctors are allowed to register patients.");

        // Generate a unique ID for the new patient
        uint patientId = idCounter;
        idCounter = idCounter.add(1);

        // Add the new patient to the patients mapping
        patients[patientId] = Patient(patientName, doctorId);

        // Add the patient ID to the patientIds array
        patientIds.push(patientId);

        // Emit the NewPatientRegistered event
        emit NewPatientRegistered(patientId, patientName, doctorId);
    }

    // Function to add a medical record for a patient
    function addMedicalRecord(uint patientId, bytes32 diagnosis, bytes32 prescription, bytes32 notes) public {
        // Only the patient's doctor is allowed to add medical records
        require(roles.isInRole(UserType.DOCTOR, msg.sender, patients[patientId].doctorId), "Only the patient's doctor is allowed to add medical records.");

        // Generate a unique ID for the new medical record
        uint medicalRecordId = idCounter;
        idCounter = idCounter.add(1);

        // Add the new medical record to the medicalRecords mapping
        medicalRecords[medicalRecordId] = MedicalRecord(diagnosis, prescription, notes);

        // Add the medical record ID to the medicalRecordIds array
        medicalRecordIds.push(medicalRecordId);

        // Emit the NewMedicalRecordAdded event
        emit NewMedicalRecordAdded(medicalRecordId, diagnosis, prescription, notes);
    }

    // Function to view a hospital's information
    function viewHospital(uint hospitalId) public view returns (bytes32 hospitalName, bytes32 hospitalAddress, bytes32 hospitalContact) {
        // Only hospitals are allowed to view hospital information
        require(roles.isInRole(UserType.HOSPITAL, msg.sender, hospitalId), "Only hospitals are allowed to view hospital information.");

        // Return the hospital's information
        return (hospitals[hospitalId].name, hospitals[hospitalId].address, hospitals[hospitalId].contact);
    }

    // Function to view a doctor's information
    function viewDoctor(uint doctorId) public view returns (bytes32 doctorName, uint hospitalId) {
        // Only hospitals are allowed to view doctor information
        require(roles.isInRole(UserType.HOSPITAL, msg.sender, doctors[doctorId].hospitalId), "Only hospitals are allowed to view doctor information.");

        // Return the doctor's information
        return (doctors[doctorId].name, doctors[doctorId].hospitalId);
    }

    // Function to view a patient's information
    function viewPatient(uint patientId) public view returns (bytes32 patientName, uint doctorId) {
        // Only the patient's doctor is allowed to view patient information
        require(roles.isInRole(UserType.DOCTOR, msg.sender, patients[patientId].doctorId), "Only the patient's doctor is allowed to view patient information.");

        // Return the patient's information
        return (patients[patientId].name, patients[patientId].doctorId);
    }

    // Function to view a medical record
    function viewMedicalRecord(uint medicalRecordId) public view returns (bytes32 diagnosis, bytes32 prescription, bytes32 notes) {
        // Only the patient's doctor is allowed to view medical records
        uint patientId = getPatientIdFromMedicalRecordId(medicalRecordId);
        require(roles.isInRole(UserType.DOCTOR, msg.sender, patients[patientId].doctorId), "Only the patient's doctor is allowed to view medical records.");

        // Return the medical record information
        return (medicalRecords[medicalRecordId].diagnosis, medicalRecords[medicalRecordId].prescription, medicalRecords[medicalRecordId].notes);
    }

    // Function to view a patient's medical records
    function viewPatientMedicalRecords(uint patientId) public view returns (uint[] memory medicalRecordIds) {
        // Only the patient's doctor is allowed to view a patient's medical records
        require(roles.isInRole(UserType.DOCTOR, msg.sender, patients[patientId].doctorId), "Only the patient's doctor is allowed to view a patient's medical records.");

        // Return the medical record IDs for the patient
        return getMedicalRecordIdsForPatient(patientId);
    }

    // Function to get a patient ID from a medical record ID
    function getPatientIdFromMedicalRecordId(uint medicalRecordId) private view returns (uint) {
        // Iterate through the patientIds array and find the patient with the matching medical record ID
        for (uint i = 0; i < patientIds.length; i++) {
            uint patientId = patientIds[i];
            uint[] medicalRecordIds = getMedicalRecordIdsForPatient(patientId);
            for (uint j = 0; j < medicalRecordIds.length; j++) {
                if (medicalRecordIds[j] == medicalRecordId) {
                    return patientId;
                }
            }
        }
        // If the medical record ID is not found, return 0
        return 0;
    }

    // Function to get the medical record IDs for a patient
    function getMedicalRecordIdsForPatient(uint patientId) private view returns (uint[] memory) {
        uint[] memory medicalRecordIds = new uint[](0);
        // Iterate through the medicalRecordIds array and find the medical records for the patient
        for (uint i = 0; i < medicalRecordIds.length; i++) {
            uint medicalRecordId = medicalRecordIds[i];
            if (getPatientIdFromMedicalRecordId(medicalRecordId) == patientId) {
                medicalRecordIds.push(medicalRecordId);
            }
        }
        return medicalRecordIds;
    }
}