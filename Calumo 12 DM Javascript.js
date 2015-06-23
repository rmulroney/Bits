/***************************************************
 * 
 *    This version of the Dimension Manager 
 *    has been edited to allow additional 
 *    functionality required by PPA.
 * 
 *       - added Entity Filter. 
 * 
 * *************************************************/



// Set the intial dimension hierarchy to be displayed.
var defaultDimension = "Account";
var defaultHierarchy = "Accounts";
var defaultPerspective = 0;

var offsetTop = -46;
var offsetLeft = -6;

/* --------------------------------------------------------
   
   Constants
   
------------------------------------------------------------*/

var storedProcServer = "DimensionManager";
var subReportName = "DM Sub";
var rngData = "data";
var rngHeader = "headings";

var schemaReport =  "DM Schema";
var rngSchemaData = "schemaData";
var rngAttributeData = "AttributeData";
var rngAttributeHeading = "AttributesHeadings";

var schemaColColumnName = 0;
var schemaColDataType = 1;
var schemaColLenghtText = 2;
var schemaColLenghtNumeric = 3;
var schemaColDefaultValue = 4;
var schemaColLookupTable = 5;
var schemaColLookupColumn = 6;

var ShowChildren = 1;
var ShowHierChildren = 2;
var ShowCurrent = 0;



//var cssHref = "http://SPAWebServer01/Calumo/api.mvc/userfilesfromdatabase/download/kendosilver";
//var dmCssHref = "http://SPAWebServer01/Calumo/api.mvc/userfilesfromdatabase/download/DM_CSS";
var downloadURL = "https://cloud.calumo.com/slsq/api.mvc/userfilesfromdatabase/download/";

var horScrollPosition = 0.15;
/* --------------------------------------------------------
   
   Global Variables
   
------------------------------------------------------------*/


var dimension;
var hierarchy; 
var perspective; 
var selectedTreeNode;
var deleteingTreeNode;
var deleteingSuccess;


//$(document).ready(function () {

   // setup postrender binding
   report.api.bind("postrender",function(){   
   
   initCSS();
   report.api.getElements("#dmTreeContext").hide();
   
   //initDimension();   
   resizeWindow();
   initWindows();
   
   kendo.bind(getWindowedDiv("#ManageControls"), viewModel);   
   kendo.bind(report.api.getElements("#ProcessCube"), processModel);      
   report.api.getElements(".InputGrids").hide();

   resetWarnings();
   createSplitter();

   createPerspectiveSelector();   
   createSelectorTree();
  
      

   }); // reportArea: bind

//}); // document: ready

/* --------------------------------------------------------
   
   Init Functions
   
------------------------------------------------------------*/


/* // not in use //
function initDimension() {
   
   dimension = getParameterByName("dimension");
   hierarchy = getParameterByName("hierarchy");
   perspective = getParameterByName("perspective"); // Rm 2014-05-02 -- Custom Perspective filter
   
   
   if (dimension === undefined || dimension === "" ) {
      dimension = defaultDimension;
      hierarchy = defaultHierarchy;
      perspective = defaultPerspective;
   }   
   
   $("#dimensionLabel").text(toTitleCase(dimension));
   
}
*/


// Binds the actions of the Create new node view. 
var viewModel = kendo.observable({        
        locations: ["Child", "Sibling", "Parent"],
        location: "Child",
        txtNewNodeName: "",
        lbError: "",
        agreed: true,
        btnNewNode: function(e) {
            e.preventDefault();
                        
            new_node(this.location, this.txtNewNodeName);
            
            //this.set("txtNewNodeName", "");
            this.set("location", "Child");
            
        }        
    });
    

// Binds the actions of the Process Model button.
var processModel = kendo.observable({                
        agreed: true,
        lbStatus: "",
        btnProcess: function(e) {
            e.preventDefault();                        
            processDimension(dimension);            
        }        
    });



function processDimension(){
   
   // Fires Process proc in [DMSchema].[ProcessProc] for this dimension.
   
   var processingStart = new Date().getTime();
   
   resetWarnings();
   
   processModel.set("lbStatus", "Dimension Processing Started.....");

   
   spdata = {
       'datasource': storedProcServer,
       'storedProcedure': 'spDMProcessDimension',
       'parameters' : "@dimension=" + dimension,
       'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
   }; 
   

   $.ajax({
       type: "POST",
       contentType: 'application/json; charset=utf-8',
       url: api.baseUrl + "ExecuteStoredProc/Execute",
       data: JSON.stringify(spdata),
       error: function(result) {             
          processModel.set("lbStatus", "Processing Failed - " + result );             
       },
       success: function(result) {
          processModel.set("lbStatus", "Processing Complete. (" + ( new Date().getTime() - processingStart) / 1000 + "s)");             
       }
   });   
      
      
}



/* --------------------------------------------------------
   
   Interface
   
------------------------------------------------------------*/

function initCSS () {
   //$("head").append('<link rel="stylesheet" type="text/css" href="' + cssHref + '"></link>');
   
   setDimensionLabel("");
   //$("head").append('<link rel="stylesheet" type="text/css" href="' + dmCssHref + '"></link>');
      
   var css = '.edit-link_' + report.instance + ' {width: 16px; height: 16px;background: transparent url("https://cloud.calumo.com/slsq/images/ExplorerTree/contextMenu/menu.png") no-repeat 50% 50%;overflow: hidden;display: inline-block;font-size: 0;line-height: 0;vertical-align: top;margin: 2px 0 0 3px;-webkit-border-radius: 5px;-mox-border-radius: 5px;border-radius: 5px;';   
   addStyleSheet(css);
   
   css = '.leafEdit-link_' + report.instance + ' {width: 16px; height: 16px;background: transparent url("https://cloud.calumo.com/slsq/images/ExplorerTree/contextMenu/menu.png") no-repeat 50% 50%;overflow: hidden;display: inline-block;font-size: 0;line-height: 0;vertical-align: top;margin: 2px 0 0 3px;-webkit-border-radius: 5px;-mox-border-radius: 5px;border-radius: 5px;';
   addStyleSheet(css);
   
   //$("#horizontalmain").css("background-color","#005BC5");
   
}


function addStyleSheet (css) {
    var head, styleElement;
    head = document.getElementsByTagName('head')[0];
    styleElement = document.createElement('style');
    styleElement.setAttribute('type', 'text/css');
    if (styleElement.styleSheet) {
      styleElement.styleSheet.cssText = css;
    } else {
      styleElement.appendChild(document.createTextNode(css));
    }
    head.appendChild(styleElement);
    return styleElement;
  }


function resizeWindow (){
   
      report.api.getElements(".reportData").css("width","99%");

      w = $(window).height();      
      pt = report.api.getElements("#TreePanel" ).position().top;
      h = w - pt - 150;
      report.api.getElements("#horizontalmain").css("height",h+"px");
      getWindowedDiv("#treeview").css("height",h+"px");         
}


function resetWarnings(){
   // Hide the Create node Error.
   viewModel.set("lbError", "");
   processModel.set("lbStatus", "");
   
}

function initWindows() {
   var windowOptions = {
       width: "300px",
       height: "400px",
       title: "Transporter",
       visible: false,
       actions: [ "Minimize", "Maximize" ]
   };
   
      
   // create the cart window      
   var transporterWindow = report.api.getElements("#window").kendoWindow(windowOptions);
   
   // Creating a window pushes it out of the report so we give it a Class which linkes it to this report.
   transporterWindow.addClass("windowTransporter_" + report.instance);

   // open on start up
   transporterWindow.data("kendoWindow").open();
   
   // create the modal windows
   windowOptions = {
       width: "600px",
       height: "175px",
       title: "Cart",
       position: {
         top: 200,
         left: 200         
       },
       visible: false       
   };
   
   
   windowOptions.title = "Group Member";
   windowOptions.modal = true;
   var groupMemberWindow = report.api.getElements("#Grids").kendoWindow(windowOptions);
   groupMemberWindow.addClass("windowGroupMember_" + report.instance);
   
   
   windowOptions.title = "Leaf Member";
   windowOptions.modal = true;
   var childGridsWindow = report.api.getElements("#ChildGrids").kendoWindow(windowOptions);
   childGridsWindow.addClass("windowChildGrids_" + report.instance);
   
}


function closeAllWindows() {
   
   $(".windowTransporter_" + report.instance).close();
   $(".windowGroupMember" + report.instance).close();
   $(".windowChildGrids_" + report.instance).close();
   
   
}



function createSplitter(){
   
   frame1H = horScrollPosition;
   
   report.api.getElements("#horizontalmain").kendoSplitter({
         orientation: "horizontal",
         panes: [
               { collapsible: true, resizable: true, size: (frame1H * 102).toString() + '%'  },
               { collapsible: true, resizable: true }
         ],
         layoutChange: onSplitterResize
    });
   splitter  = report.api.getElements("#horizontalmain").data("kendoSplitter");
   
   /*
      //IE 8 and 9 return 0 for $("#reportArea").height()
      if($("#reportArea").height()-60 < 150) {
         
         var h = Number($(window).height()) - 60;
         
         if( h >= 150) {
            $("#horizontalmain").height(h); 
         } else {
            $("#horizontalmain").height(700); 
         } 
      } else {
         $("#horizontalmain").height($("#reportArea").height()-50);
      }
   
*/
}


function onSplitterResize(){
   horScrollPosition = report.api.getElements("#hierSelector").width() / report.api.getElements("#horizontalmain").width();
}



function setDimensionLabel(label) {   
   report.api.getElements("#dimensionLabel").text(toTitleCase(label));
}



/* --------------------------------------------------------
   
   Tree View Functions
   
------------------------------------------------------------*/



function createBodyTrees() {
   
//Creates the Tree's in the main body of the report.

   //safely remove the existing trees
   var treeview = getWindowedDiv("#treeview").data("kendoTreeView");
   if (treeview !== undefined) treeview.destroy();
         
   var cartTreeview = getWindowedDiv("#cartTreeView").data("kendoTreeView");
   if (treeview !== undefined) cartTreeview.destroy();

   createCartTreewView();
   createTreeView();
   
   setDimensionLabel(dimension);
   
}


function createSelectorTree() {

// This treeview controls which Dimension Hierarchy we're editing.

   report.api.getElements("#hierSelector").html();
   var hierSelectorTreeview =  report.api.getElements("#hierSelector").kendoTreeView({
      dragAndDrop: true,
      animation: {
          collapse: {
            duration: 200
          },
           expand: {
             duration: 200
         }
        },
      dataTextField: "label",
      dataImageUrlField: "imageURL" ,
      dataSource: new kendo.data.HierarchicalDataSource({
           type: "json",
           serverFiltering: false,
           transport: {
              read: function (options) {               
                 
                 var value = options.data.value;               
      			options.success(getHierarchyNodes(value, 'DM', 0, 0));               
      		} //read
      	}, //transport
      	schema: {
      		model: {
      			id: "value",
      			hasChildren: "hasChildren"
      		}
      	},
      	sort: {
      		field: "sortOrder",
      		dir: "asc"
      	}
      }) // datasource
  }); // treeview: kendoTreeView*/

  getWindowedDiv("#cartTreeView").css("height", "99%");

    
  var treeview = report.api.getElements("#hierSelector").data("kendoTreeView");
  treeview.bind("drop", 
    function (e) {   
       e.setValid(false);
    });
  treeview.bind("select", onSelectSelectorTree);   

}



function createCartTreewView(){

// This tree is the transporter, a place holder for the user to move nodes around the tree. 

  getWindowedDiv("#cartTreeView").html("");
  var cartTreeview =  getWindowedDiv("#cartTreeView").kendoTreeView({
      dragAndDrop: true,
      animation: {
          collapse: {
            duration: 200
          },
           expand: {
             duration: 200
         }
        },
      dataTextField: "label",
      dataImageUrlField: "imageURL"		
   }); // treeview: kendoTreeView*/
   
   getWindowedDiv("#cartTreeView").css("height", "99%");
      
   var treeview = getWindowedDiv("#cartTreeView").data("kendoTreeView");
   treeview.bind("drop", tree_drop);
   
   
}



function createTreeView() {
      
// This tree display's the Hierarchy. 

  getWindowedDiv("#treeview").html("");
  getWindowedDiv("#treeview").kendoTreeView({
    // Template for the context menu
    template: kendo.template ("#: item.label # # if (item.isLeaf == 'false' || !item.isLeaf) { # <a class='edit-link_"  + report.instance + "' href='\\\\#'></a>  # } else {# <a class='leafEdit-link_"  + report.instance + "' href='\\\\#'></a> # } #"),
		dragAndDrop: true,
      animation: {
          collapse: {
            duration: 200
          },
           expand: {
             duration: 200
         }
        },
      dataTextField: "label",
      dataImageUrlField: "imageURL",
		dataSource: new kendo.data.HierarchicalDataSource({
			type: "json",
			serverFiltering: false,
			transport: {
				read: function (options) {               
               
					var value = options.data.value;
					options.success(getHierarchyNodes(value, dimension, hierarchy, perspective));
					bindEditLinks();
					
				} //read
			}, //transport
			schema: {
				model: {
					id: "value",
					hasChildren: "hasChildren"
				}
			},
			sort: {
				field: "sortOrder",
				dir: "asc"
			}
		}) // datasource
      
	}); // treeview: kendoTreeView

   

  // Bind the treeview edit icon (from the template) to the report action.
  //report.api.getElements(".edit-link").on("click", showEditGroupWindow);
  //report.api.getElements(".leafEdit-link").on("click", showEditLeafWindow);
  bindEditLinks();
  
  
  

  // bind  to allow attaching, detaching and resorting
  var treeview = getWindowedDiv("#treeview").data("kendoTreeView");
  treeview.bind("drop", tree_drop);
  treeview.bind("select", tree_select);   
    


  // expand the First node on load.
  treeview.toggle(".k-item:first");
  

  selectFirstTreeNode();

}


function bindEditLinks(){
   // causes the modal window popup
   $(".edit-link_"  + report.instance).on("click", showEditGroupWindow);
   $(".leafEdit-link_"  + report.instance).on("click", showEditLeafWindow);
  
}



function getHierarchyNodes(value, dim, hier, persp) {
      
  if (typeof value === "undefined") {		
    value = 0;
  }


  //Get the data for this member.
  //var sproc = "spDMTreeHierarchy";   
  var sproc = "spDMCustomTreeHierarchy";     //Rm 2014-05-02 -- custom perspective filter
  var param = [
    {name: "parentId",  value: value},
    {name: "HierView",  value: dim},
    {name: "Hierarchy",  value: hier},
    {name: "Children",  value: ShowChildren},
    {name: "Perspective",  value: persp}  //Rm 2014-05-02 -- custom perspective filter
  ];


    
  var grid = getSPData(storedProcServer, sproc, param, rngData);      
   
	// get kendo hierarchical datasource
	var columnList = ["value", "label", "hasChildren", "isCalculated", "unaryOperator", "reportingScale", "isLeaf", "sortOrder"];
	var fields = {
		value: {type: "number"},
		label: {type: "string"},
		hasChildren: {type: "boolean"},
		isCalculated: {type: "boolean"},
		unaryOperator: {type: "string"},
      reportingScale: {type: "number"},
		isLeaf: {type: "boolean"},
		sortOrder: {type: "number"}
	};
      
	var dataSource = getKendoHierarchicalDataSource(grid, columnList, fields);

	return updateDataSourceTreeIcon(dataSource);
	

} // getHierarchyNodes



function getKendoHierarchicalDataSource (grid, columnList, fields) {
	var dataSource = [];
	_.each(grid, function(values, rowIndex) {
		var row = {};
		_.each(values, function(value, column) {
			var parser = fields[columnList[column]].type || "default";
			return (row[columnList[column]] = parsers[parser](value));
		});
		return dataSource.push(row);
	});
	return dataSource;
} // getKendoHierarchicalDataSource



function updateDataSourceTreeIcon(dataSource) {
      
  //Extend the tree node datasource with the imageURL

  var images = {
    "false": {"0":  "ico_folder", "1": "ico_folder", "2": "ico_folder", "DMFolder": "ico_folder", "DMLeaf": "ico_hier" },
    "true": {"0": "ico_folder", "1": "ico_slsq", "2": "ico_slsq", "3": "ico_slsq", "DMFolder": "ico_folder", "DMLeaf": "ico_hier" }   
  };
   var img;
   
   
  _.each(dataSource, function(values, rowIndex) {
     console.log(values);
      values.imageURL = downloadURL + images[values.isLeaf][values.unaryOperator || 0];    
    
  });

  return dataSource;

}



function onSelectSelectorTree(e) {
   
   //When the Selected item in the Hierarchy Selector changes. 

   var hierTreeview = report.api.getElements("#hierSelector").data("kendoTreeView");      
   var node = hierTreeview.dataItem(e.node);
   var parent = hierTreeview.parent(e.node);      
   
   if (node.isLeaf === true) {      
      dimension = hierTreeview.text(parent);
      hierarchy = node.label;
      
      if (perspective === undefined) perspective = 0;  
      
      createBodyTrees();            
   }   
}




function tree_drop(e) {

   
  // Handles a node being moved within the hierarhy.

   resetWarnings();
   
   // We're only going to update the DB where the destination node is in the main tree.
	var treeview = getWindowedDiv("#treeview").data("kendoTreeView");
  var destinationNode = treeview.dataItem(e.destinationNode);

   
  var cartTreeview = getWindowedDiv("#cartTreeView").data("kendoTreeView");
  var sourceNode = cartTreeview.dataItem(e.sourceNode);   
   
  // the source is also valid if it comes from the main tree.
  if (sourceNode === undefined) {
    sourceNode = treeview.dataItem(e.sourceNode);   
  }
   
  if (destinationNode !== undefined && sourceNode !== undefined) {
    
  /*
    console.log("Source: " + sourceNode.id); // which node is moving?
    console.log("Destination: " + destinationNode.id); // where are we moving too?
    console.log("dropPosition: " + e.dropPosition); // tells us what funtion to perform: "over" = New Parent, "before" || "after" = sort order,
  */
    
    // Expand the destination node - if we don't do this the moving node will appear in the interface twice.  
    var togglingElement = treeview.findByUid(destinationNode.uid);    // get the UID for the destination data item
    //treeview.toggle(togglingElement);
    // or 

    //treeview.toggle(destinationNode)


    if (destinationNode.isLeaf === true) {

    
       // Stop users from moving the root node on the main tree - moving the root of the cart tree is fine.
       _.each(e.sourceNode.classList, function(c) { 
          if(c === "k-first") {
             e.setValid(false);
             return;      
          }         
       });
    
       // no drop leaf on leaf               

       if (e.dropPosition === 'over') {			
          e.setValid(false);
          return;


       }
    }    
    // move the dimension member in the DB  
    move_node(e.dropPosition, sourceNode.id, destinationNode.id);         
  }
}


function showEditGroupWindow(e) {

   getWindowedDiv("#Grids").data("kendoWindow").open();         
   /*console.log("showEditGroupWindow");
   console.log(this.position);
       
   

   console.log("left: " + $(this).offset().left + ", offsetLeft: " + offsetLeft + ", top:" + $(this).offset().top + ", offsetTop: " + offsetTop);
   
   $("#dmTreeContext").css({left: $(this).offset().left + offsetLeft, top: $(this).offset().top + offsetTop});
   */
   
}


function showEditLeafWindow(e) {   
   getWindowedDiv("#ChildGrids").data("kendoWindow").open();
   
   //$("#ChildGrids").data("kendoWindow").open();      
   console.log("showEditLeafWindow");
   
   //$("#dmTreeContext").css({left: $(this).offset().left + offsetLeft, top: $(this).offset().top + offsetTop});
   
}



function tree_select(e) {   
 
  // When the selected hierarchy member changes. 

   resetWarnings();


  var treeview = getWindowedDiv("#treeview").data("kendoTreeView");
  var node = treeview.dataItem(e.node);   
 
  // Update the Selected Node Global variable.
  selectedTreeNode = node.id;


  // Create the current and Child Grids
  createNodeTables(node.id);   


}


function move_node(position, node, targetNode) {   
   resetWarnings();


   
   
   //Executes the Node movement Stored Proc to update the dimension tables.

   // TBC - Add login ID
   spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMTreeMove]',
          'parameters' : "@dimensionHier='" +dimension  + ", @hierarchy=" + hierarchy + ", @node="+node+" ,@targetNode="+targetNode+" ,@position="+position,
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
   };
   
   $.ajax({
       type: "POST",
       contentType: 'application/json; charset=utf-8',
       url: window.api.baseFullUrl + "ExecuteStoredProc/Execute",
       data: JSON.stringify(spdata),
       success: function(result) {          
       },
       error: function(result) {
            console.log("Move_node: Error: ");
             alert(result);
          }
   });
   


   // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute.
   createNodeTables(selectedTreeNode);
   
}


function new_node(position, newNodeName) {   

// New nodes are created via a Calumo report. This is because the API's cexecstoredproc does not return results 
// and we need to know what the new node's ID before adding it to the TreeView.

   var targetNode = selectedTreeNode;
   
   
   var sproc = "spDMTreeNewNode";   
   var param = [
      {name: "dimensionHier", value: dimension},
      {name: "hierarchy",     value: hierarchy},
      {name: "targetNode",    value: targetNode},
      {name: "position",      value: position},

      {name: "newName",       value: newNodeName}
      //{name: "perspective",   value: perspective}
   ];
      
   
   var grid = getSPData(storedProcServer, sproc, param, rngData);  
   


   //Test to see if the Node was created Correctly.
   // on error the report returns a value starting with "#EXCEPTION!"
   //ie - "#EXCEPTION!Leaf Nodes may not become Parents"
   
   var firstCell = grid[0];
   
   if (firstCell[0].indexOf("#EXCEPTION") !== -1) {
      // Error on Creation       
      //Output error near new member txtbox.
      viewModel.set("lbError", "Error: " + firstCell[0].replace("#EXCEPTION!", ""));
      
   } else {
      
      resetWarnings();

      // get data for the new node. 
      var columnList = ["value", "label", "hasChildren", "isCalculated", "unaryOperator", "reportingScale",  "isLeaf", "sortOrder"];
      var fields = {	
        label: {type: "string"},
        hasChildren: {type: "boolean"},
        isCalculated: {type: "boolean"},
        unaryOperator: {type: "string"},
        reportingScale: {type: "string"},
        isLeaf: {type: "boolean"},
        sortOrder: {type: "number"},
        value: {type: "number"}
      };

            
      var gridDataSource = report.api.getKendoDataSource(grid, true, columnList, fields);
 
      // Add the icon to the new treeview node
      //updateDataSourceTreeIcon(updateDataSourceTreeIcon);
         
      // Get a ref to the treeview
      var treeview = getWindowedDiv("#treeview").data("kendoTreeView");
      
      // Find the dataItem in the treeview's datasource
      var targetNodeDataItem = treeview.dataSource.get(targetNode);  
      
      if(targetNodeDataItem !== undefined){
         
         // get the UID for this data item
         var targetNodeElement = treeview.findByUid(targetNodeDataItem.uid);   
         
         // Add the new member node to the Treeview. 
         switch(position){
            case "Child":
               // Append to Parent Node.
               treeview.append(gridDataSource.transport.data[0], targetNodeElement);
               break;
            case "Parent":
               // Add as Sibling to the Target
                var newNodeDataItem =treeview.insertBefore(gridDataSource.transport.data[0], targetNodeElement);      
               
               //Append the Target to the new node.             
               treeview.append(targetNodeElement, newNodeDataItem);
               
               // For some reason the Append creates duplicate children of the new node
               treeview.remove(targetNodeElement);
               
               break;
            case "Sibling":
               // add after the target node on the same level
               treeview.insertAfter(gridDataSource.transport.data[0], targetNodeElement);      
               break;
            default:
               treeview.append(gridDataSource.transport.data[0], targetNodeElement);
               break;
         }
      }
      
      // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute. 
      createNodeTables(selectedTreeNode);
      bindEditLinks();
      
   }
   
   // New member could be fired from a stored proc, but it does not  provide a method for 
   // returning information about the new member and so cannot be easily added to the tree. 
   /*spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMTreeNewNode]',
          'parameters' : "@dimensionHier='" +dimension+ "', @targetNode="+targetNode+", @position="+position+", @newName='"+newNodeName+"'",
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
   };
   
   $.report.api({
       type: "POST",
       contentType: 'application/json; charset=utf-8',
       url: api.baseUrl + "ExecuteStoredProc/Execute",
       data: JSON.stringify(spdata),
       success: function(result) {         
         createNodeTables(selectedTreeNode);          
         
       }
   });*/

   
}


function updateTreeLabel(value, newLabel) {
// Update the text of a treeView node based on the Dimension ID passed..  

   // Get a ref to the treeview
   var treeview = getWindowedDiv("#treeview").data("kendoTreeView");
   
   // Find the dataItem in the treeview's datasource
   var changingDataItem = treeview.dataSource.get(value);   
   if(changingDataItem !== undefined){
      
      // get the UID for this data item
      var changingElement = treeview.findByUid(changingDataItem.uid);   
      
      // Update the treeview node to the new label
      treeview.text(changingElement, newLabel); 
   }
}         


function deleteTreeLabel(value) {
// Deletes a node from the tree with a Dimension ID of value param.


   // Get a ref to the treeview
   var treeview = report.api.getElements("#treeview").data("kendoTreeView");
   
   // Find the dataItem in the treeview's datasource
   var changingDataItem = treeview.dataSource.get(value);   
   if(changingDataItem !== undefined){
      
      // get the UID for this data item
      var changingElement = treeview.findByUid(changingDataItem.uid);   
      
      // Update the treeview node to the new label
      treeview.remove(changingElement); 
   }
   
   if( value == selectedTreeNode) {
      selectFirstTreeNode(selectedTreeNode);
   }
}         


function selectFirstTreeNode() {
   
   var treeview = getWindowedDiv("#treeview").data("kendoTreeView");
   var dataItem = treeview.dataItem(".k-item:first");  
   
   if (dataItem !== undefined){
      treeview.select(dataItem);      
      selectedTreeNode = dataItem.value;
      createNodeTables(selectedTreeNode);
   }
   
}


/* --------------------------------------------------------
   
   Dimension Selector
   
------------------------------------------------------------*/


/*
function createDimensionSelector() {
   
   // Loads the Dimension selector in the DM report header.   
   
   var sproc = "spDMDimensions";   
   var param = [         ];   
   var grid = getSPData(storedProcServer, sproc, param, rngData);   
   
   
	// get kendo hierarchical datasource
	var columnList = ["dimension"];
	var fields = {		
		dimension: {type: "string"}
	};
   
	var dataSource = getKendoHierarchicalDataSource(grid, columnList, fields);
   
   
   $("#selectorDimension").kendoComboBox({
      dataTextField: "dimension",
      dataValueField: "dimension",
      filter: "contains",
      suggest: true,
      dataSource: dataSource,      
      change: function() {
         var value = $("#selectorDimension").val();
         window.location.replace(location.pathname+"?dimension=" + encodeURIComponent(value) );               
      }
   });
   
   // choose the first Dimension in the list if one was not passed as part of the query string. 
   if (dimension === undefined || dimension === "") {      
      dimension = $("#selectorDimension").val();          
   } else {
      $("#selectorDimension").data("kendoComboBox").value(dimension);      
   }
   
   
}


function createHierarchySelector() {
   
   // Loads the Hierarchy selector in the DM report header.
   
   var sproc = "spDMHierarchies";   
   var param = [
      {name: "dimension",  value: dimension}   
   ];
   
   var grid = getSPData(storedProcServer, sproc, param, rngData);      
   
   
   // get kendo hierarchical datasource
	var columnList = ["hierarchy"];
	var fields = {		
		hierarchy: {type: "string"}
	};
      
	var dataSource = getKendoHierarchicalDataSource(grid, columnList, fields);   
   
   $("#selectorHierarchy").kendoComboBox({
      dataTextField: "hierarchy",
      dataValueField: "hierarchy",
      filter: "contains",
      suggest: true,
      dataSource: dataSource,      
      change: function() {
         var value = $("#selectorHierarchy").val();
         window.location.replace(location.pathname+"?dimension=" + encodeURIComponent(dimension) + "&hierarchy=" + encodeURIComponent(value) );
      }
   });
   
   var dcmb = $("#selectorHierarchy").data("kendoComboBox");
   dcmb.select(0); 
   
   // choose the first Dimension in the list if one was not passed as part of the query string. 
   if (hierarchy === undefined || hierarchy === "") {            
      hierarchy = $("#selectorHierarchy").val();
      
   } else {
      $("#selectorHierarchy").data("kendoComboBox").value(hierarchy);      
   }
         
}
*/


function createPerspectiveSelector() {
   
   // Loads the Hierarchy selector in the DM report header.
   
   var sproc = "spGetSites";   
   var param = [];   
   var grid = getSPData(storedProcServer, sproc, param, rngData);      
   
   
   // get kendo hierarchical datasource
   var columnList = ["label", "value"];
   var fields = {
      model: { 
         label: {type: "number"},
         value: {type: "string"}      
      }
   };   
	var dataSource = report.api.getKendoDataSource(grid, true, columnList, fields); 
   
   //create the Kendo Combo
   report.api.getElements("#selectorPerspective").kendoComboBox({
      
      dataTextField: "label",
      dataValueField: "value",
      filter: "contains",
      suggest: true,         
      index: 0,      
      dataSource: dataSource,      
      change: function() {
         perspective = report.api.getElements("#selectorPerspective").val();         
         createBodyTrees();
      }
   });
   
   var dcmb = report.api.getElements("#selectorPerspective").data("kendoComboBox");
   dcmb.select(0); 
   
   // choose the first Dimension in the list if one was not passed as part of the query string. 
   if (perspective === undefined || perspective === "") {            
      perspective = report.api.getElements("#selectorPerspective").val();
      
   } else {
      report.api.getElements("#selectorPerspective").data("kendoComboBox").value(perspective);      
   }
         
}


function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]").toLowerCase();       
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),      
        results = regex.exec(location.search.toLowerCase());
    return results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}


function toTitleCase(str) {
    return str.replace(/(?:^|\s)\w/g, function(match) {
        return match.toUpperCase();
    });
}

/* --------------------------------------------------------
   
   Node Editor Tables
   
------------------------------------------------------------*/

function createNodeTables(value)   {
   

   createHierTable("#CurrentNode", ".SelectedNode", value, ShowCurrent); //Shows the currently selected note from the treeview
   createHierTable("#HierNodes", ".SummaryNodes", value, ShowHierChildren); //Show the Children of the current node that are also parents.
   createAttributeEditorTable("#ChildNodes", ".AttributeNodes", value, ShowChildren);  // show the leaf nodes in the attribute editor
   

   getWindowedDiv("#ManageControls").show();   
   getWindowedDiv("#ChildGrids").show();   
   
   
}

/* --------------------------------------------------------
   
   Non-leaf Editor Table
   
------------------------------------------------------------*/

function createHierTable(tableDiv, divClass, value, children) {   
         
      
   var sproc = "spDMTreeHierarchy";   
   var param = [
      {name: "parentId",  value: value},
      {name: "HierView",  value: dimension},
      {name: "Hierarchy",  value: hierarchy},
      {name: "Children",  value: children}      
   ];
   
   var grid = getSPData(storedProcServer, sproc, param, rngData);  

	// get kendo hierarchical datasource
	var columnList = ["value", "label", "hasChildren", "isCalculated", "unaryOperator", "reportingScale", "isLeaf", "sortOrder"];
	var fields = {
		
		label: {type: "string"},
		hasChildren: {type: "boolean"},
		isCalculated: {type: "boolean"},
		unaryOperator: {type: "string"},
      reportingScale: {type: "number"},
		isLeaf: {type: "boolean"},
		sortOrder: {type: "number"},
      value: {type: "number"}
	};

   var gridDataSource = report.api.getKendoDataSource(grid, true, columnList, fields);   
   


   
      //"#ChildNodes"
      getWindowedDiv(tableDiv).kendoGrid({
            dataSource : gridDataSource,
            //height: 500,
            //width: 600,
            sortable: true,
            filterable: false,
            //selectable: "multiple cell",
            resizable: false,

            reorderable: false,               
            //editable: true,         
            editable: {
             confirmation: false
            },            
            columns: [{               
                   command: "destroy",
                   width: 90,
                   attributes: {
                      "class": "table-cell",
                     style: "text-align: left; font-size: 11px"                  
                 }


            },  {/*
                 field: "value",
                 width: 90,
                 title: "ID"            
            } ,  {                   
                 field: "reportingScale",
                 width: 90,
                 title: "Scale"                 

             },  {*/                   
                 field: "label",
                 title: "Member Name"                 
             }]
             
         });   
   

      
   // if there's no data to display then hide then grid view.
   
   if (gridDataSource.view().length > 0) {      

      report.api.getElements(divClass).show();         
      var q = getWindowedDiv(tableDiv).data("kendoGrid");
      q.bind("save", fireHierUpdate);      
      q.bind("remove", verifyDelete);      
      
   } else {      
     // $(divClass).hide();
   }
}


function fireHierUpdate(e){
   // This update is used by the parent and current member tables
   
   var value = e.model.value;            
   
   // which row type  is being updated?
   if (e.model.isLeaf === true || e.model.isLeaf == "true") {
       isLeaf = "Leaf";
   } else {
       isLeaf = "Hier";        
   }
         
   
   // Pass the update information to the DM Update Stored Proc. 
   for(var name in e.values){         
            
      spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMAttributeUpdate]',
          'parameters' : "@dimension='" + dimension  + ", @hierarchy=" + hierarchy + ", @tableType="+ isLeaf +", @node=" + value + " ,@AttributeColumn=" + name + " ,@newValue='" + e.values[name] + "'",
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
      };

      
      $.ajax({
          type: "POST",
          contentType: 'application/json; charset=utf-8',
          url: windowapi.baseUrl + "ExecuteStoredProc/Execute",
          data: JSON.stringify(spdata),
          error: function(result) {
             console.log(result);
             alert(result);
          }
          
          /* ,
          success: function(result) {
          }*/
      });   
      
      // If the update affects the treeview label, then update that node in the treeview
      if (name == "label" || name == "label ") {
         updateTreeLabel(value, e.values[name]);         
      }
   } 
   
   // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute.
   createNodeTables(selectedTreeNode);
   
}

function fireHierDelete(value){
   //calls the delete member stored Proc. 
   
   spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMDelete]',
          'parameters' : "@dimension='" + dimension + ", @hierarchy=" + hierarchy + ", @node=" + value,
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
      };
      
      $.ajax({
          type: "POST",
          contentType: 'application/json; charset=utf-8',
          url: api.baseUrl + "ExecuteStoredProc/Execute",
          data: JSON.stringify(spdata) ,
          success: function(result) {
             
             deleteingSuccess = result.success;             
             
             if (deleteingSuccess === true || deleteingSuccess == "true") {                  
                  // Update the grids to ensure that they're reporting the correct data. 
                  createNodeTables(selectedTreeNode);
               
                  // delete the tree node
                  deleteTreeLabel(deleteingTreeNode);         
             } else {
                  console.log(result);
                  alert(result);                                 
             }
          },
          error: function(result) {
             console.log(result);
             alert(result);
          }
          
      });
}

function verifyDelete(e) {
   // Fire stored proc that test is a node can be deleted.
   // Enables the the developer to set their own business logic on delete. 
   
   
   e.preventDefault();
   deleteingTreeNode = e.model.value;
   
    spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMVerifyDelete]',
          'parameters' : "@dimension='" + dimension + ", @hierarchy=" + hierarchy + ", @node=" + deleteingTreeNode,
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
      };
      
      $.ajax({
          type: "POST",
          contentType: 'application/json; charset=utf-8',
          url: api.baseUrl + "ExecuteStoredProc/Execute",
          data: JSON.stringify(spdata) ,
          success: function(result) {
             
             if(result.success === true || result.success == "true"){
                fireHierDelete(deleteingTreeNode);
             } else {
                console.log(result);
                alert(result.errorMessages);
                createNodeTables(selectedTreeNode);                
             }
            
          },
          error: function(result) {
             console.log(result);
             alert(result);
          }
      });         
      
}


/* --------------------------------------------------------
   
   Leaf Attribute Editor Table
   
------------------------------------------------------------*/


function createAttributeEditorTable(tableDiv, divClass, node, children) {
   
   
   // Dimension member list.   
   
   
   var sproc = "spDMLeafAttributes";   
   var param = [
      {name: "node",  value: node},
      {name: "dimension",  value: dimension},
      {name: "Hierarchy",  value: hierarchy},
      {name: "Children",  value: children}      
   ];
   
   var grid = getSPData(storedProcServer, sproc, param, rngData);  
   var headings = getSPData(storedProcServer, sproc, param, rngHeader);  
   
   headings = headings[0];
   
   // Provides information about the souce table data types and foreign keys. 
   sproc = "spDMTableDefinition";   
   param = [      
      {name: "Dimension",  value: dimension},
      {name: "Hierarchy",  value: hierarchy},
      {name: "TableType",  value: "Leaf"}  
   ];
   var schema = getSPData(storedProcServer, sproc, param, rngData); 

   
   // Grid's Column Definitions.
   var columnSchema = [];   
   columnSchema.push({width: 50, title: "ID", field: "value" });
   columnSchema.push({width: 90, title: "Member Name", field: "label" });
       
   // Build the dynamic datasource definition. 
   var sfields = "var fields = {value: {type: \"number\", readonly: true}, label: {type: \"string\"}";      
   for (var prop in schema) {             
      for (var col in headings) {            
         
         if (headings[col] === schema[prop][0]) {                     
            switch(schema[prop][schemaColDataType]){
               case "int":

                  
                  // build Schema definition
                  sfields = sfields  + ", " + schema[prop][schemaColColumnName] + ": { type: \"number\", validation: { required: true, min: 1} }";
                  
                  // Add as Column to Kendo Grid                  
                  if (schema[prop][schemaColLookupTable] === "" || schema[prop][schemaColLookupTable] === undefined) {
                                                              
                     columnSchema.push({width: 5 * parseInt(schema[prop][schemaColLenghtNumeric]), 
                                        title: schema[prop][schemaColColumnName], 
                                        field: schema[prop][schemaColColumnName]                                        
                     });                                                                                                                          
                  } else {
                                       
                        columnSchema.push({width: 5 * parseInt(schema[prop][schemaColLenghtNumeric]), 
                                        title: schema[prop][schemaColColumnName], 
                                        field: schema[prop][schemaColColumnName],
                                        values: foreginKeyData(schema[prop][schemaColLookupTable],
                                                               schema[prop][schemaColLookupColumn])});                                  
                  }

                  break;
               default:
                  
                  // build Schema definition
                  sfields = sfields  + ", " + schema[prop][schemaColColumnName] + ": {type: \"string\"}";  
                  
                  // Add as Column to Kendo Grid
                  if (schema[prop][schemaColLookupTable] === "" || schema[prop][schemaColLookupTable] === undefined) {
                                                              
                     columnSchema.push({width: 2.5 * parseInt(schema[prop][schemaColLenghtText]), 
                                     title: schema[prop][schemaColColumnName], 
                                     field: schema[prop][schemaColColumnName]});
                  } else {
                     
                     columnSchema.push({width: 2.5 * parseInt(schema[prop][schemaColLenghtText]), 
                                     title: schema[prop][schemaColColumnName], 
                                     field: schema[prop][schemaColColumnName],
                                     values: foreginKeyData(schema[prop][schemaColLookupTable],
                                                            schema[prop][schemaColLookupColumn])});                           
                  }
                  break;
            }
         }         
      }            
   }   
   sfields = sfields + "};";   
   
   // Create the Data Fields object.
   eval(sfields);
   
   // Create the Grid Datasource. 
   var gridDataSource = report.api.getKendoDataSource(grid, true, headings, fields);      
      
   report.api.getElements(tableDiv).kendoGrid({         
               dataSource : gridDataSource,
               filterable: true,                              
               columns: columnSchema,
               editable: true,
               sortable: true,               
               resizable: true,
               reorderable: true            
         });
   
   // if there's no data to display then hide then grid view.
   if (gridDataSource.view().length > 0) {
      report.api.getElements(divClass).show();
      
      // Bind the Save event to the handler function.
      var q = report.api.getElements(tableDiv).data("kendoGrid");
      q.bind("save", fireAttributeUpdate);
      
   } else {
      report.api.getElements(divClass).hide();
   }

}


function foreginKeyData(FKtableName, FKColumn) {
   
   // Proc which provides the foreign key lookup   
   
   var sproc = "spDMForeignKeylookup";   
   var param = [
      {name: "FKTable",  value: FKtableName},
      {name: "FKColumn",  value: FKColumn}      
   ];
   
   var lgrid = getSPData(storedProcServer, sproc, param, rngData);     
   
   var fkData = [];  
   
   // re-shape the data for a kendo combobox.
   for (var x in lgrid) {       
      fkData.push({ "value": lgrid[x][0], "text": lgrid[x][1]});
   }
   
   return fkData;            
}


function fireAttributeUpdate(e){
   
   // Pass the update information to the DM Update Stored Proc. 
   var value = e.model.value;            
   for(var name in e.values){         
            
            
      spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMAttributeUpdate]',
          'parameters' : "@dimension='" + dimension + ", @hierarchy=" + hierarchy + ", @tableType=Leaf, @node=" + value + " ,@AttributeColumn=" + name + " ,@newValue='" + e.values[name] + "'",
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
      };      
      
      
      $.ajax({
          type: "POST",
          contentType: 'application/json; charset=utf-8',
          url: api.baseUrl + "ExecuteStoredProc/Execute",
          data: JSON.stringify(spdata),
          error: function(result) {
             console.log(result);
             alert(result);
             
          }/* ,
          success: function(result) {
          }*/
      });   
      
      // If the update affects the treeview label, then update that node in the treeview
      if (name == "label" || name == "label ") {
         updateTreeLabel(value, e.values[name]);         
      }
      
   }      
   
   // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute.
   createNodeTables(selectedTreeNode);   
}

/* --------------------------------------------------------

      Interface Helpers

   --------------------------------------------------------*/
   
   
function getWindowedDiv(divId){
   
   
   // Anything that we push into a window pop-up out of the reach of report.api 
   // so we need to find it in the DOM. 
   
   switch (divId){
      case "#cartTreeView":
         return $(".windowTransporter_" + report.instance + " > #cartTreeView" );  // reads as "find the window for this report instance"  and it's Child with the id "report.api.getElements("
         break;
         
      case "#Grids":
         return $(".windowGroupMember_" + report.instance );  
         break;
         
      case "#ChildGrids":
         return $(".windowChildGrids_" + report.instance );
         break;
         
      case "#CurrentNode":
         return $(".windowGroupMember_" + report.instance +" > #CurrentNode" );  
         break;
         
      case "#HierNodes":
         return $(".windowChildGrids_" + report.instance).find("#ManageControls");
         break;
         
      case "#ManageControls":
         return  $(".windowGroupMember_" + report.instance).find("#ManageControls");
         break;
         
      default:  
         return report.api.getElements(divId);
   }
   
   
}
   
   
   

/* --------------------------------------------------------
   
   Fetch data helpers
   
------------------------------------------------------------*/




function getSPData(server, sproc, param, rng){   

   
   var queryString = "&sproc=" + sproc + "&server=" + storedProcServer;      
   
   for (index = 0; index < param.length; ++index) {     
    queryString = queryString + "&Name" + index + "=" + param[index].name + "&param" + index + "=" + param[index].value;
   }
   
   // get data grid from report
   
   var grid = report.api.getCalculatedRange(subReportName, rng, true, queryString);
      
   return grid;
}


var parsers = {
  number: function(value) {
    return kendo.parseFloat(value);
  },
  date: function(value) {
    return kendo.parseDate(value);
  },
  "boolean": function(value) {
    if (typeof value === "string") {
      return value.toLowerCase() === "true";
    }
    return value !== null ? !! value : value;
  },
  string: function(value) {
    return value !== null ? value + "" : value;
  },
  "default": function(value) {
    return value;
  }
}; // parsers
   



/*function insertElement (selector, tagName, element) {
  var html = _.extend(document.createElement(tagName), element);
    $(selector).append(_.extend(document.createElement(tagName), element));
}*/
