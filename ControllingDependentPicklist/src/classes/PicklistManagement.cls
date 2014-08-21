/*

--STEPS TO CREATE METADATA SERVICE--
- Generating a valid Apex MetadataService class
      - Download and edit the WSDL
           - Change the Port name from 'Metadata' to 'MetadataPort'
           - As of Summer'13 (API 28) there was a small bug in the CustomField type definition, change the 'type' element definition to include a minOccurs="0" atttribute, as per the other elements in this type.
      - Generate Apex from this WSDL
           - When prompted give it a name of MetadataServiceImported
           - Verify a MetadataServiceImported class has been created
      - Run the Patch script to generate a new MetadataService class (as a Document)
           - Ensure you have a Document Folder called MetadataServicePatcher (Developer Name)
           - Run the following code from execute annoynmous in Developer Console
                 MetadataServicePatcher.patch();
           - Verify this has created a MetadataServicePatched Document in the abov folder
      - Update MetadataService.cls
           - Open the MetadataServicePatched Document and copy the code          
           - Paste the code over the current or new MetadataService.cls class 
               (recommend MavensMate for this as the file is some 8000+ lines long)
      - Update MetadataServiceTest.cls
           - See this for guidelines http://andyinthecloud.com/2013/05/11/code-coverage-for-wsdl2apex-generated-classes
           - Future releases of the patch script may also generate this class

*/

public class PicklistManagement{

    public MetadataService.AsyncResult result {get;set;}
    public MetadataService.SaveResult resultsave {get;set;}
    public String ControllingFieldName {get;set;}
    public String DependentFieldName {get;set;}
    public String DependentFieldLabel {get;set;}
    public String ObjectName {get;set;}
    public pagereference createPicklistField()
    {
        try
        {
        MetadataService.MetadataPort service = createService();     
        MetadataService.CustomField customField = new MetadataService.CustomField();
        //customField.fullName = 'Reusable__c.SubCategory__c';
        customField.fullName = ObjectName+'.'+DependentFieldName;
        //customField.label = 'Sub Category Picklist';
        customField.label = DependentFieldLabel;
        customField.type_x = 'Picklist';
        
        List<ControlDependentList__c> FieldRelList =[Select Name,ControllingFieldValue__c,DependentFieldValue__c,Default__c from ControlDependentList__c];
                
        metadataservice.Picklist pt = new metadataservice.Picklist(); // create picklist metadata
            pt.sorted= false;
            pt.controllingField = ControllingFieldName;
        
        List<metadataservice.PicklistValue> lstpickval = new List<metadataservice.PicklistValue>();
        
        System.debug('Before For loop: '+pt);
        
        for(ControlDependentList__c pickObj:FieldRelList){
                metadataservice.PicklistValue pickval = new metadataservice.PicklistValue();
                pickval.fullName= pickObj.Name;
                pickval.default_x=pickObj.Default__c;
                String[] strCntrlArray = pickObj.ControllingFieldValue__c.split(',');
                pickval.controllingFieldValues = strCntrlArray;  // assign controlling field values
                lstpickval.add(pickval);
            }
        
        System.debug('after For loop: ');
        System.debug('After End API call: '+lstpickval);
        
        //pt.picklistValues = new list{one,two}; // assign picklist values
        pt.picklistValues = lstpickval;
        customField.picklist = pt ;                                       // assign Picklist
        MetadataService.AsyncResult[] results = service.create(new List<MetadataService.Metadata>{customField});
        
        result=results[0];
        displayStatus();
        
        System.debug('After End API call: ');
        }
        catch(Exception e)
        {
            System.debug('Error: '+e);
        }
        return null;
    }
    
    public PageReference checkStatus()
    {
        // Check status of the request
        result = createService().checkStatus(new List<String> { result.Id })[0];
        displayStatus();
        return null;
    }
    
    public void displayStatus()
    {
        // Inspect the AsyncResult and display the result
        
        if(result !=null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,
                    result.done ? 'Request completed' : 'Request in progress...'));
            if(result.state == 'Error')
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, result.message));
            if(result.done)
                result = null;
        }
    }
    
    public pagereference UpdatePicklistField()
    {
        try
        {
            MetadataService.MetadataPort service = createService();
             MetadataService.CustomField customField = new MetadataService.CustomField(); 
                //customField.fullName = 'Reusable__c.SubCategory__c';
                customField.fullName = ObjectName+'.'+DependentFieldName;
                //customField.label = 'Sub Category Picklist';
                customField.label = DependentFieldLabel;
                customField.type_x = 'Picklist'; 
                
            metadataservice.Picklist pt = new metadataservice.Picklist();
                pt.sorted= false;
                pt.controllingField= ControllingFieldName;
                
           List<ControlDependentListUpdate__c> FieldRelList =[Select Name,ControllingFieldValue__c,DependentFieldValue__c,Default__c from ControlDependentListUpdate__c];
           List<metadataservice.PicklistValue> lstpickval = new List<metadataservice.PicklistValue>();
            
            System.debug('Before For loop: '+pt+'----FieldRelList---'+FieldRelList);
            
            for(ControlDependentListUpdate__c pickObj:FieldRelList){
                    metadataservice.PicklistValue pickval = new metadataservice.PicklistValue();
                    pickval.fullName= pickObj.Name;
                    pickval.default_x=pickObj.Default__c;
                    String[] strCntrlArray = pickObj.ControllingFieldValue__c.split(',');
                    pickval.controllingFieldValues = strCntrlArray;  // assign controlling field values
                    lstpickval.add(pickval);
                }
           pt.picklistValues = lstpickval;
           customField.picklist = pt ; 
           
           MetadataService.UpdateMetadata ut = new MetadataService.UpdateMetadata();
                ut.currentName=ObjectName+'.'+DependentFieldName;
                ut.metadata= customField;
           MetadataService.SaveResult[] results = service.updateMetadata(new List<MetadataService.Metadata>{customField});
           resultsave=results[0];
       }
        catch(Exception e)
        {
            System.debug('Error: '+e);
        }
      
       return null;   
    }
    
    public static MetadataService.MetadataPort createService()
    { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;     
    }
}