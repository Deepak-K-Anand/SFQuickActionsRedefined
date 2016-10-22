/**
 * Utilizing QuickActions in Salesforce
 * to spin up Custom Pages to perform various
 * actions.
 *
 * This is actually reverse engineering
 * what SF provides. Back in VF the only
 * way to use QuickAction(s) is via
 * the <chatter:feed> tag. But this comes
 * with a Chatter Feed. The attempt here
 * was to isolate the QuickAction or Publisher
 * Action from the Chatter Feed and use it
 * separately. And hence this library!
 *
 * The whole thing works in 2 parts: There
 * is QuickActionMetadata page and this
 * QuickActionRenderer page. The former uses
 * the Force.com AJAX Toolkit's describeQuickActions(...)
 * routine to get the metadata about the QuickAction
 * and then uses the Form Post technique to
 * send the collected data to the next page i.e.,
 * QuickActionRenderer. 
 *
 * The QuickActionRenderer then uses a
 * combination of apex:repeat and apex:inputField
 * tags to render out a layout that would closely
 * resemble the actual QuickAction.
 *
 * @author  	Talent Rover Inc.
 * @version  	1.0
 */
public class QuickActionRenderer {
    /**
     * A Class describing the 
     * structure of Field.
     */
    public class Field {
        public Integer index                                { get; set; }
        public String name                                  { get; set; } 
        public String label                                 { get; set; } 
    }

    /**
     * A Class describing the
     * structure and composition
     * of a pre-defined QuickAction
     * in Salesforce.
     */
    public class QuickActionMetadata {
        public String label                                 { get; set; } 
        public String iconUrl                               { get; set; } 
        public String targetSobjectType                     { get; set; } 
        public String targetParentField                     { get; set; } 
        public String type                                  { get; set; }
        public String visualforcePageName                   { get; set; }
        public String visualforcePageUrl                    { get; set; }
        public List<Field> fields                           { get; set; } 
    }

    /**
     * Determine the mode of the rendered
     * QuickAction which could either of
     * these: Create, Update or VF Page.
     */
    public String mode                                      { get; set; }
    
    /**
     * Determine whether a slds-card
     * container needs to be shown
     * around Quick Action form.
     */
    public Boolean showContainer                            { get; set; }
    
    /**
     * Stores a TRUE if there is
     * Metadata available. This a security
     * measure to prevent the page from
     * throwing an error if opened separately
     * and not via the QuickActionMetadata.
     */
    public Boolean isMetadataAvailable                      { get; set; }
    public QuickActionMetadata metadata                     { get; set; }
    
    /**
     * Stores a TRUE if there are
     * "odd" number of fields on the
     * Quick Action Layout.
     */
    public Boolean oddNumberOfFields                        { get; set; }
    
    /**
     * Stores the list of IDs of
     * Parent Record(s) against which
     * the Child Record will be created
     * via the Quick Action.
     */
    public List<Id> parentIds                               { get; set; }
    public SObject anyObject                                { get; set; }
    public Boolean hasCompleted                             { get; set; }
    public Boolean hasError                                 { get; set; }
    public String errorMessage                              { get; set; }
    
    /**
     * ctor
     */
    public QuickActionRenderer() {
        processRequestHeaders();
    }
    
    /**
     * Perform INSERT / UPDATE
     * depending on the deciphered
     * mode.
     */
    public void save() {
        try { 
            if( parentIds.isEmpty() ) {
                hasError = FALSE;
                
                if( mode == 'Create' ) {
                    INSERT anyObject;
                }
                else if( mode == 'Update' ) {
                    UPDATE anyObject;
                }
            }
            else {
                List<SObject> recordsToCreate = new List<SObject>();
                
                for( Id parentRecordId : parentIds ) {
                    /**
                     * For each of the passed in
                     * Parent Record, create a Child
                     * Record.
                     */
                    SObject sObjClone = anyObject.clone();
                    
                    sObjClone.put( metadata.targetParentField, parentRecordId );
                    
                    recordsToCreate.add( sObjClone );
                }
                
                hasError = FALSE;
                
                INSERT recordsToCreate;
            }
        }
        catch( DMLException dmlEx ) { 
            hasError        = TRUE;
            errorMessage    = dmlEx.getMessage();
        }
        
        hasCompleted = TRUE;
    }
    
    /**
     * Process the request headers as
     * received from the QuickActionMetadata
     * page via a Form Post.
     *
     * Data is passed from the QuickActionMetadata
     * page via a Form Post as we have a lot of data
     * to receive(a whole chunk of JSON) and most
     * importantly this needs to be available at the 
     * time of page load. Hence the only option was
     * a Form Post as URL Parameters will not suffice.
     */
     @TestVisible
    private void processRequestHeaders() {
        String metadataJSON = ApexPages.currentPage().getParameters().get( 'metadata' );
        String parentId     = ApexPages.currentPage().getParameters().get( 'parentId' );
        String entityId     = ApexPages.currentPage().getParameters().get( 'entityId' );
        showContainer       = ApexPages.currentPage().getParameters().get( 'container' ) == '1' ? TRUE : FALSE;
        
        parentIds           = new List<Id>();
        
        /**
         * If serialized JSON of the metadata is
         * available.
         *
         * A security measure to prevent the VF
         * Page from throwing an Error when opened
         * separately and not via the VF Page - 
         * QuickActionMetadata.
         */
        if( !String.isBlank( metadataJSON ) ) {
            metadata = ( QuickActionMetadata )JSON.deserialize( 
                metadataJSON, 
                QuickActionMetadata.class
            );
            
            isMetadataAvailable = TRUE;
            
            /**
             * A QuickAction can be primarily
             * of 2 different types: Create and
             * VF Page.
             */
            if( metadata.type != 'VisualforcePage' ) {
                anyObject = Schema.getGlobalDescribe().get( metadata.targetSobjectType ).newSObject();
                
                mode = 'Create';
                
                /**
                 * If only a single Parent Record is
                 * supplied.
                 */
                if( !String.isBlank( parentId ) && 
                    parentId != NULL            && 
                    !parentId.contains( ',' ) 
                ) {
                    anyObject.put( metadata.targetParentField, parentId );
                }
                /**
                 * When multiple Parent Records
                 * have been supplied.
                 */
                else if( 
                    !String.isBlank( parentId ) && 
                    parentId != NULL            && 
                    parentId.contains( ',' ) 
                ) {
                    parentIds = parentId.split( ',' );
                }
                
                /**
                 * Ad mentioned before, a QuickAction
                 * can only be either "Create" or
                 * "VF Page". But we are utilizing the
                 * "Create" Action Layout to also
                 * perform Updates.
                 *
                 * So if we get a valid "entityId" aka
                 * a record Id in the Request Parameters
                 * from the QuickActionMetadata VF Page
                 * then we declare this will be utilized
                 * for an Update Action.
                 */
                if( !String.isBlank( entityId ) && 
                    entityId != NULL
                ) {
                    mode = 'Update';
                    
                    List<String> fieldNames = new List<String>();
                    
                    for( Field fd : metadata.fields ) {
                        fieldNames.add( fd.name );
                    }
                    
                    /**
                     * We need to a SOQL and get
                     * the data in all the fields
                     * for the given entity.
                     */
                    String soql = 
                        ' SELECT '      + String.join( fieldNames, ',' )   + 
                        ' FROM '        + metadata.targetSobjectType       + 
                        ' WHERE Id=\''  + entityId + '\'';
                    
                    anyObject = Database.query( soql );
                }
                
                /**
                 * Set the "oddNumberOfFields" to
                 * TRUE. This is used in the VF Page
                 * yo determined if the field in the
                 * last row needs to be in full width
                 * or not as if it's odd it will not
                 * have a partner on the right hand side
                 * column.
                 */
                oddNumberOfFields = Math.mod( metadata.fields.size(), 2 ) != 0;
            }
            else {
                mode = 'VF Page';
            }
        }
    }
}