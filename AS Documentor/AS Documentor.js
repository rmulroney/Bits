// Set the intial dimension hierarchy to be displayed.
var defaultDimension = "Nominal";
var defaultHierarchy = "Nominal";
var globalNode;

/* --------------------------------------------------------
   
   Constants
   
------------------------------------------------------------*/

var storedProcServer = "SSASmetadata";
var subReportName = "DM Sub";
var rngData = "data";
var rngHeader = "headings";

var ShowChildren = 1;
var ShowHierChildren = 2;
var ShowCurrent = 0;

var cssHref = "https://cloud.calumo.com/savills/api.mvc/userfilesfromdatabase/download/DM_CSS";
var detailReportUrl = "https://cloud.calumo.com/Savills//api.mvc/reports/AS%20Report";

var icoURL = "https://cloud.calumo.com/savills/api.mvc/userfilesfromdatabase/download/";
var icoCatalog = "ico_catalog";
var icoCube = "ico_cube";
var icoDim = "ico_dim";
var icoHier = "ico_hier";
var icoMeasure = "ico_measure";
var icoMeasureGroup = "ico_measureGroup";
var icoLevel = "ico_report";
var icoRoot = "ico_folder";
var icoElse = "ico_report";



/* --------------------------------------------------------
   
   Global Variables
   
------------------------------------------------------------*/


var dimension;
var hierarchy; 
var selectedTreeNode;
var deleteingTreeNode;
var deleteingSuccess;



$(document).ready(function () {
   
   
   
   $("head").append('<link rel="stylesheet" type="text/css" href="' + cssHref + '"></link>');
    
   // setup postrender binding
   $("#reportArea").bind("report.PostRender", function () {
      
   
   
   resizeWindow();      
   createTreeView();
   
      
	}); // reportArea: bind

}); // document: ready



/* --------------------------------------------------------
   
   Interface
   
------------------------------------------------------------*/

function resizeWindow (){
         $(".reportData").css("width","99%");         
}


/* --------------------------------------------------------
   
   Tree View Functions
   
------------------------------------------------------------*/

function createTreeView() {
      
   
   $("#treeview").kendoTreeView({
		//template: kendo.template (data),
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
					options.success(cdata_accounts(value));
				} //read
			}, //transport
			schema: {
				model: {
					id: "value",
					hasChildren: "hasChildren"
				}
			},
			sort: {
				field: "label",
				dir: "asc"
			}
		}) // datasource
      
	}); // treeview: kendoTreeView

	// bind tree_drop to allow attaching, detaching and resorting
	var treeview = $("#treeview").data("kendoTreeView");
	treeview.bind("drop", tree_drop);
   treeview.bind("select", tree_select);   
   
   // expand the First node on load.
   //treeview.toggle(".k-item:first");
   
   //selectFirstTreeNode();
   
}


var parsers = {
	number: function(value) {
		return value;
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

function insertElement (selector, tagName, element) {
	var html = _.extend(document.createElement(tagName), element);
    $(selector).append(_.extend(document.createElement(tagName), element));
}

function cdata_accounts(value) {
   
   
	if (typeof value === "undefined") {		
      value = "root";
	}
   

   // get the data for this member.
   var sproc = "spGetDocTreeNode";   
   var param = [
      {name: "parentId",  value: value},      
      {name: "Children",  value: ShowChildren}      
   ];
   
   var grid = getSPData(storedProcServer, sproc, param, rngData);      
      
   
	// get kendo hierarchical datasource
	var columnList = ["value", "label", "hasChildren", "isCalculated", "nodeType", 
                              "catalogName", "cubeName", "dimensionName", "hierName", "isLeaf"];
	var fields = {
		value: {type: "string"},
		label: {type: "string"},
		hasChildren: {type: "boolean"},
		isCalculated: {type: "boolean"},
		nodeType: {type: "string"},
      catalogName: {type: "string"},
      cubeName: {type: "string"},
		dimensionName: {type: "string"},
      hierName: {type: "string"},
      isLeaf: {type: "boolean"}
		
	};
	var dataSource = getKendoHierarchicalDataSource(grid, columnList, fields);
   
      
	//extend datasource with imageURL
	/*var images = {
		"+": {"false": "tv_plus", "true": "tv_plus_f"},
		"-": {"false": "tv_minus", "true": "tv_minus_f"},
		"~": {"false": "tv_tilde", "true": "tv_tilde_f"}
	};
	_.each(dataSource, function(values, rowIndex) {
		values.imageURL = downloadURL + images[values.unaryOperator || "+"][values.isCalculated || false];
	});*/
   
   
   var icoURL = "https://cloud.calumo.com/savills/api.mvc/userfilesfromdatabase/download/";
   var icoCatalog = "ico_catalog";
   var icoCube = "ico_cube";
   var icoDim = "ico_dim";
   var icoHier = "ico_hier";
   var icoMeasure = "ico_measure";
   var icoMeasureGroup = "ico_measureGroup";
   
   var currentIco;
   
   _.each(dataSource, function(values, rowIndex) {      
      
      
      
      switch(values.nodeType) {
         case "catalog":
            currentIco = icoURL + icoCatalog;
            break;
         case "cube":
            currentIco = icoURL + icoCube;
            break;
         case "dimension":
            currentIco = icoURL + icoDim;
            break;
         case "hierarchy":
            currentIco = icoURL + icoHier;
            break;
         case "level":
            currentIco = icoURL + icoLevel;
            break;
         case "measure":
            currentIco = icoURL + icoMeasure;
            break;
         case "measureGroup":
            currentIco = icoURL + icoMeasureGroup;
            break;
         case "root":
            currentIco = icoURL + icoRoot;
            break;
         default:
            currentIco = icoURL + icoElse;
            break;
      }
      
      
      
      
      values.imageURL =  currentIco;      
   });
	
	return dataSource;
	
} // cdata_accounts

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


function tree_drop(e) {
   
 e.preventDefault();

}


function tree_select(e) {   
   
   var treeview = $("#treeview").data("kendoTreeView");
   var node = treeview.dataItem(e.node);   
   globalNode = treeview.dataItem(e.node);   
   
   if( treeview.dataItem(e.node).label !== "Dimensions" &&
         treeview.dataItem(e.node).label !== "Calculated Measures" &&
         treeview.dataItem(e.node).label !== "Measure Groups" &&
         treeview.dataItem(e.node).cubeName !== ""
   ) {
            
      var qs = "?&CatalogName=" + treeview.dataItem(e.node).catalogName +
                  "&CubeName="+   treeview.dataItem(e.node).cubeName+
                  "&DimensionName="+   treeview.dataItem(e.node).dimensionName+
                  "&HierName="+   treeview.dataItem(e.node).hierName+
                  "&ObjectType=" + treeview.dataItem(e.node).nodeType + 
                  "&ObjectName=" + treeview.dataItem(e.node).label + 
                  "&HT=True";
      
      
      $("#metadata").attr("src",detailReportUrl + qs );
      // Update the Selected Node Global variable.
      selectedTreeNode = node.id;
      
   }
}



function new_node(position, newNodeName) {   

// New nodes are created via a report. This is because the API's cexecstoredproc does not return results 
// and we need to know what the new node's ID before adding it to the TreeView.

   var targetNode = selectedTreeNode;
   
   
   var sproc = "spDMTreeNewNode";   
   var param = [
      {name: "dimensionHier", value: dimension},
      {name: "hierarchy",     value: hierarchy},
      {name: "targetNode",    value: targetNode},
      {name: "position",      value: position},
      {name: "newName",       value: newNodeName}      
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
      
      

      // get data for the new node. 
      var columnList = ["value", "label", "hasChildren", "isCalculated", "nodeType", "isLeaf"];
      var fields = {	
      label: {type: "string"},
      hasChildren: {type: "boolean"},
      isCalculated: {type: "boolean"},
      nodeType: {type: "string"},
      isLeaf: {type: "boolean"},      
      value: {type: "number"}
      };

            
      var gridDataSource = report.api.getKendoDataSource(grid, true, columnList, fields);
         
      // Get a ref to the treeview
      var treeview = $("#treeview").data("kendoTreeView");
      
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

   }
   
   // New member could be fired from a stored proc, but it provides not method for 
   // returning information about the new member and so cannot be easily added to the tree. 
   /*spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMTreeNewNode]',
          'parameters' : "@dimensionHier='" +dimension+ "', @targetNode="+targetNode+", @position="+position+", @newName='"+newNodeName+"'",
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
   };
   
   $.ajax({
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
   var treeview = $("#treeview").data("kendoTreeView");
   
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
// Deletes a node from the with a Dimension ID of value param.


   // Get a ref to the treeview
   var treeview = $("#treeview").data("kendoTreeView");
   
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
   
   var treeview = $("#treeview").data("kendoTreeView");
   var dataItem = treeview.dataItem(".k-item:first");  
   
   if (dataItem !== undefined){
      treeview.select(dataItem);      
      selectedTreeNode = dataItem.value;      
   }
   
}



/* --------------------------------------------------------
   
   Fetch data helpers
   
------------------------------------------------------------*/



//function getSPData(sproc, server, paams){
function getSPData(server, sproc, param, rng){   
   
   var queryString = "&sproc=" + sproc + "&server=" + storedProcServer;      
   
   for (index = 0; index < param.length; ++index) {     
    queryString = queryString + "&Name" + index + "=" + param[index].name + "&param" + index + "=" + param[index].value;
   }
      
   // get data grid from report   
   var grid = report.api.getCalculatedRange(subReportName, rng, true, queryString);
   
   return grid;
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

