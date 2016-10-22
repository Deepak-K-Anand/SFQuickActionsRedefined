/**
 * [QuickActionMetadata JavaScript object that wraps all the Constants, Helpers and Actions using a Module Pattern]
 * @author      [Talent Rover]
 * @version     [1.0]
 * @type        {Object}
 */
var QuickActionMetadata = {
    constants : {
        /**
         * [elements Ids of Various Elements on the Page]
         * @type {Object}
         */
        elements    : {
            HDN_METADATA    : "hdnMetaData",
            HDN_PARENTID    : "hdnParentId",
            HDN_ENTITYID    : "hdnEntityId",
            HDN_CONTAINER   : "hdnContainer",
            FRM_RENDERER    : "frmRenderer"
        },
        /**
         * [quickActionTypes Possible types of QuickActions]
         * @type {Object}
         */
        quickActionTypes : {
            CREATE       : "Create",
            LOG_A_CALL   : "LogACall",
            VF_PAGE      : "VisualforcePage"
        },
        params      : {}
    },
    /**
     * [helpers Utility Functions]
     * @type {Object}
     */
    helpers : {
        /**
         * The Force.com AJAX Toolkit has been utilized
         * to grab the metadata information about the 
         * Quick Action. "sforce" is an object exposed
         * when you include the Force.com AJAX Toolkit in
         * the VF Page. In order to use the same we have
         * to first initialize the "sforce" object with the
         * current Session Id.
         * 
         * @param  {[string]} sessionId     Current Session Id
         * @return {[object]} QuickAction.helpers object
         */
        initializeSforce : function( sessionId ) {
            if( window.sforce ) {
                sforce.connection.sessionId = sessionId;
            }
            
            return QuickActionMetadata.helpers;
        },
        /**
         * A utility function to grab the URL parameters.
         * All the collected URL Parameters will be saved
         * into the "params" property of the
         * QuickActionMetadata.constants object.
         * 
         * @return {[object]} QuickAction.helpers object
         */
        getUrlParameters : function() {
            var params  = QuickActionMetadata.constants.params;
            var query   = window.location.search.substring( 1 );
            var vars    = query.split( "&" );
            
            for ( var i = 0; i < vars.length; i++ ) {
                var pair = vars[i].split( "=" );
                
                if ( typeof params[pair[0]] === "undefined" ) {
                    params[pair[0]] = decodeURIComponent( pair[1] );
                }
                else if ( typeof params[pair[0]] === "string" ) {
                    var arr         = [params[pair[0]], decodeURIComponent( pair[1] )];
                    params[pair[0]] = arr;
                }
                else {
                    params[pair[0]].push( decodeURIComponent( pair[1] ) );
                }
            }
            
            return QuickActionMetadata.helpers;
        },
        /**
         * At the minimum the "action" attribute has to
         * be specified in order to to fetch the metadata
         * information about the QuickAction.
         * 
         * @return {Boolean}
         */
        hasValidParams : function() {
            var params = QuickActionMetadata.constants.params;
            
            if( 
                params.action           &&
                params.action !== null  &&
                params.action !== ""
            ) {
                return true;
            }
            
            return false;
        }
    },
    /**
     * [actions Functions that Interact with Apex/API]
     * @type {Object}
     */
    actions : {
        processMetadata : function( metadata ) {
            var quickActionTypes = QuickActionMetadata.constants.quickActionTypes;
            
            var processedMetadata = {
                label               : metadata.label,
                iconUrl             : metadata.iconUrl,
                targetSobjectType   : metadata.targetSobjectType,
                targetParentField   : metadata.targetParentField,
                type                : metadata.type
            };
                        
            switch( metadata.type ) {
                /**
                 * We need to grab and process
                 * the metadata only for those
                 * QuickActions of type:
                 * "Create" and "LogACall".
                 */
                case quickActionTypes.CREATE        :
                case quickActionTypes.LOG_A_CALL    :
                    var fields      = {};
                    var counter     = 1;
                    if( parseInt( metadata.layout.rows ) > 0 ) {
                        fields = [];
                        
                        /**
                         * At times when there is just one row
                         * Salesforce carries an object in the
                         * "layout" property instead of an array.
                         * To make things consistent we are transforming
                         * the same to an array.
                         */
                        if( parseInt( metadata.layout.rows ) == 1 ) {
                            metadata.layout.layoutRows = [ metadata.layout.layoutRows ];
                        }
                        
                        metadata.layout.layoutRows.forEach(
                            function( layoutRow ) {
                                if( parseInt( layoutRow.numItems ) > 0 ) {
                                    layoutRow.layoutItems.forEach(
                                        function( layoutItem ) {
                                            /**
                                             * This is one of the compelling
                                             * reason why we utilized Force.com
                                             * AJAX Toolkit's describeQuickActions
                                             * routine instead of the Apex version.
                                             *
                                             * In certain cases such as when the Quick-
                                             * Action has a compound field say the
                                             * Name field on the Contact(which comes with
                                             * Title, FirstName, MiddleName and LastName)
                                             * the Apex version of the describeQuickActions
                                             * doesn't yield these sub fields and thus
                                             * were forced to use the describeQuickActions
                                             * on the AJAX Toolkit.
                                             */
                                            if( layoutItem.hasOwnProperty( "layoutComponents" ) ) {
                                                if( layoutItem.layoutComponents.hasOwnProperty( "components" ) &&
                                                    layoutItem.layoutComponents.components.length > 0 
                                                ) {
                                                    /**
                                                     * In the case of a compound field,
                                                     * there will be not be a label for
                                                     * these sub fields and hence the
                                                     * name itself will be used as the
                                                     * label.
                                                     */
                                                    layoutItem.layoutComponents.components.forEach(
                                                        function( component ) {
                                                            fields.push(
                                                                {
                                                                    index   : counter++,
                                                                    name    : component.value,
                                                                    label   : component.value
                                                                }
                                                            );
                                                        }
                                                    );
                                                }
                                                /**
                                                 * Ensure that we are not
                                                 * dealing with a "Blank"
                                                 * placeholder on the layout.
                                                 */
                                                else if( layoutItem.layoutComponents.type !== "EmptySpace" ) {
                                                    fields.push(
                                                        {
                                                            index   : counter++,
                                                            name    : layoutItem.layoutComponents.value,
                                                            label   : layoutItem.label
                                                        }
                                                    );
                                                }
                                            }
                                        }
                                    );
                                }
                            }
                        );
                    }
                    
                    processedMetadata.fields = fields;
                    
                    return processedMetadata;
                /**
                 * There isn't much metadata to
                 * capture for a VF Page based
                 * action!
                 */
                case quickActionTypes.VF_PAGE :
                    processedMetadata.visualforcePageName   = metadata.visualforcePageName;
                    processedMetadata.visualforcePageUrl    = metadata.visualforcePageUrl;
                    
                    return processedMetadata;
            }
        },
        /**
         * Utilize the "describeQuickActions" routine
         * on the Force.com AJAX Toolkit to retrieve the
         * metadata about the specified QuickAction.
         */
        getQuickActionMetadata : function() {
            var params      = QuickActionMetadata.constants.params;
            var actions     = QuickActionMetadata.actions;
            
            /**
             * Form the name of the QuickAction by 
             * concatenating the "object" parameter and the
             * "action" parameter from the URL.
             */
            var actionName  = [ ( params.object ? ( params.object + "." ) : "" ) + params.action ];
            var metadata    = sforce.connection.describeQuickActions( actionName );
            
            if( metadata.length > 0 ) {
                var processedMetadata = actions.processMetadata( metadata[0] );
                
                /**
                 * Upon the retrieval of "metadata"
                 * re-direct to the VF Page - 
                 * QuickActionRenderer.
                 */
                actions.renderQuickActionMetadata( processedMetadata );
            }
        },
        /**
         * [renderQuickActionMetadata Fill the Hidden Input Elements on the Form with the acquired data and submit]
         * @param  {[object]} processedMetadata [The required nodes from the metadata of a QuickAction]
         */
        renderQuickActionMetadata : function( processedMetadata ) {
            var constants = QuickActionMetadata.constants;
            
            /**
             * JSON serialized metadata
             */
            document.getElementById( constants.elements.HDN_METADATA ).value = JSON.stringify( processedMetadata );
            
            /**
             * The Id of the Parent record
             * if supplied.
             */
            if( constants.params.parentId ) {
                document.getElementById( constants.elements.HDN_PARENTID ).value = constants.params.parentId;
            }
            
            /**
             * The Id of the Entity(this is
             * when we are utilizing the QuickAction
             * to perform an Update to the record)
             * if supplied.
             */
            if( constants.params.entityId ) {
                document.getElementById( constants.elements.HDN_ENTITYID ).value = constants.params.entityId;
            }
            
            /**
             * Determine whether a container
             * has to be shown around the
             * generated form or not.
             */
            if( constants.params.container ) {
                document.getElementById( constants.elements.HDN_CONTAINER ).value = constants.params.container;
            }
            
            /**
             * Programatically submit the form!
             */
            document.getElementById( constants.elements.FRM_RENDERER ).submit();
        }
    },
    init : function() {
        var helpers = QuickActionMetadata.helpers;
        var actions = QuickActionMetadata.actions;
        
        helpers.initializeSforce( arguments[0] ).getUrlParameters();

        if( helpers.hasValidParams() ) {
            actions.getQuickActionMetadata();
        }
    }
};