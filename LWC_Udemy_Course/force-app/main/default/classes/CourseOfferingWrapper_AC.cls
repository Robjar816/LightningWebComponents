public class CourseOfferingWrapper_AC {
    
    public String id;
    public String courseId;
    public String courseCode;
    public String courseAvailabilityId;
    public String course_type;
    public String title;
    public String description;
    public String code;
    public String syllabusId;
    public String modality;
    public String status;
    public String locationId;
    public String site_Code;
    public String classroom_version;
    public String site_oid;
    public String offeringType;
    public String defaultCredits;
    public String maxNumberOfStudents;
    public String numberOfStudents;
    public String enrollmentAccept;
    public String note;
    public String vleCode;
    public siteAddress siteAddress;
    public dateRange dateRange;
    
    public class siteAddress {
        public String line1;
        public String line2;
        public String city;
        public String state;
		public String zipCode;        
    }
    
    public class dateRange {
        public String startDate;
        public String endDate;
    }
}