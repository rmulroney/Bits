var gr;
var isLeaf;

/* --------------------------------------------------------
   
   Constants
   
------------------------------------------------------------*/

var storedProcServer = "MYOB";
var schemaReport =  "treeview_schema";
var schemaColColumnName = 0;
var schemaColDataType = 1;
var schemaColLenghtText = 2;
var schemaColLenghtNumeric = 3;
var schemaColDefaultValue = 4;
var schemaColLookupTable = 5;
var schemaColLookupColumn = 6;
var rngAttributeData = "AttributeData";
var rngAttributeHeading = "AttributesHeadings";
var rngSchemaData = "schemaData";

var lookupReport = "treeview_FKlookup";
var rngLookupData = "LookupData";

var ShowChildren = 1;
var ShowHierChildren = 2;
var ShowCurrent = 0;

//var downloadURL = "http://localhost/calumo/images/DMtree2.png";

/* --------------------------------------------------------
   
   Global Variables
   
------------------------------------------------------------*/

var downloadURL;
var dimension;
var selectedTreeNode;



$(document).ready(function () {
   
   
   dimension = getParameterByName("dimension");
   if (dimension === undefined || dimension === "") {
      dimension = "Account";
   }
   
 
   // setup postrender binding
   $("#reportArea").bind("report.PostRender", function () {

   kendo.bind($("#ManageControls"), viewModel);   
   $("#ManageControls").hide();   
   createDimensionSelector();
   CreateTreeView();
   
      
      // insert custom treeview style
      //var style = {type: "text/css", rel: "stylesheet", href: downloadURL + "tv_css"};
      //insertElement ("head", "link", style);
   
   	//setup treeview, get treeview template first
	   //$.get(downloadURL + "tv_template", function (data) {
			
			
		//}); // get tv_template
      
         
		
		
	}); // reportArea: bind

}); // document: ready

/* --------------------------------------------------------
   
   Init Functions
   
------------------------------------------------------------*/



var viewModel = kendo.observable({        
        locations: ["Child", "Sibling", "Parent"],
        location: "Child",
        txtNewNodeName: "",
        agreed: true,
        btnNewNode: function(e) {
            e.preventDefault();
                        
            new_node(this.location, this.txtNewNodeName);
            
            this.set("txtNewNodeName", "");
            this.set("location", "Child");
            
        }        
    });





/* --------------------------------------------------------
   
   Tree View Functions
   
------------------------------------------------------------*/

function CreateTreeView() {
   $("#treeview").kendoTreeView({
		//template: kendo.template (data),
		dragAndDrop: true,
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
				field: "sortOrder",
				dir: "asc"
			}
		}) // datasource
      
	}); // treeview: kendoTreeView

	// bind tree_drop to allow attaching, detaching and resorting
	var treeview = $("#treeview").data("kendoTreeView");
	treeview.bind("drop", tree_drop);
   treeview.bind("select", tree_select);
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
		return value != null ? !!value : value;
	},
	string: function(value) {
		return value != null ? value + "" : value;
	},
	"default": function(value) {
		return value;
	}
}; // parsers

function insertElement (selector, tagName, element) {
	var html = _.extend(document.createElement(tagName), element);
    $(selector).append(_.extend(document.createElement(tagName), element));
};

function cdata_accounts(value) {
   
	if (typeof value === "undefined") {
		value = 0;
	};
   

	// get data grid from report
	var queryString = "&R1C1=" + value + "&R2C1=" + dimension +"&R3C1=" + ShowChildren;
	var grid = report.api.getCalculatedRange("treeview_data", "data", true, queryString);
   

	// get kendo hierarchical datasource
	var columnList = ["value", "label", "hasChildren", "isCalculated", "unaryOperator", "isLeaf", "sortOrder"];
	var fields = {
		value: {type: "number"},
		label: {type: "string"},
		hasChildren: {type: "boolean"},
		isCalculated: {type: "boolean"},
		unaryOperator: {type: "string"},
		isLeaf: {type: "boolean"},
		sortOrder: {type: "number"}
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
   
   _.each(dataSource, function(values, rowIndex) {
      console.log(downloadURL);
   	values.imageURL = downloadURL;      
   });
	
	return dataSource;
	
}; // cdata_accounts

function getKendoHierarchicalDataSource (grid, columnList, fields) {
	var dataSource = [];
	_.each(grid, function(values, rowIndex) {
		var row = {};
		_.each(values, function(value, column) {
			var parser = fields[columnList[column]].type || "default";
			return row[columnList[column]] = parsers[parser](value);
		});
		return dataSource.push(row);
	});
	return dataSource;
}; // getKendoHierarchicalDataSource

function tree_drop(e) {

	var treeview = $("#treeview").data("kendoTreeView");
	var destinationNode = treeview.dataItem(e.destinationNode);
   var sourceNode = treeview.dataItem(e.sourceNode);   
   
   /*console.log("Source: " + sourceNode.id); // which node is moving?
   console.log("Destination: " + destinationNode.id); // where are we moving too?
   console.log("dropPosition: " + e.dropPosition); // tells us what funtion to perform: "over" = New Parent, "before" || "after" = sort order,*/

   if (destinationNode.isLeaf === undefined || destinationNode.isLeaf) {
		// no drop leaf on leaf
		if (e.dropPosition === 'over') {			
         e.setValid(false);
         return 
		}
	} 
   
   move_node(e.dropPosition, sourceNode.id, destinationNode.id);   
};



function tree_select(e) {

   var treeview = $("#treeview").data("kendoTreeView");
	var node = treeview.dataItem(e.node);   
   
   // Update the Selected Node Global variable.
   selectedTreeNode = node.id;
   
   // Create the current and Child Grids
   createNodeTables(node.id);   
	
};

function move_node(position, node, targetNode) {   
   
   //Add login ID
   spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMTreeMove]',
          'parameters' : "@dimensionHier='" +dimension+ "', @node="+node+" ,@targetNode="+targetNode+" ,@position="+position,
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
   };
   
   $.ajax({
       type: "POST",
       contentType: 'application/json; charset=utf-8',
       url: api.baseUrl + "ExecuteStoredProc/Execute",
       data: JSON.stringify(spdata),
       success: function(result) {
       }
   });
   
   // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute.
   createNodeTables(selectedTreeNode);
   
}


function new_node(position, newNodeName) {   
      
   var targetNode = selectedTreeNode;
      
   spdata = {
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
       }
   });
   
   // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute.
   createNodeTables(selectedTreeNode);
   
}


/* --------------------------------------------------------
   
   Dimension Selector
   
------------------------------------------------------------*/


function createDimensionSelector() {
   
   // get data grid from report
   
	var grid = report.api.getCalculatedRange("treeview_dimensions", "data", true, "");
   
	// get kendo hierarchical datasource
	var columnList = ["dimension"];
	var fields = {		
		dimension: {type: "string"}
	};
	var dataSource = getKendoHierarchicalDataSource(grid, columnList, fields);
   
   
   $("#selector").kendoComboBox({
      dataTextField: "dimension",
      dataValueField: "dimension",
      filter: "contains",
      suggest: true,
      dataSource: dataSource,      
      change: function() {
         var value = $("#selector").val();
         window.location.replace(location.pathname+"?dimension=" + encodeURIComponent(value) );               
      }
   });
   
   $("#selector").data("kendoComboBox").value(dimension);
   
}


function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]").toLowerCase();       
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),      
        results = regex.exec(location.search.toLowerCase());
    return results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}


/* --------------------------------------------------------
   
   Node Editor Tables
   
------------------------------------------------------------*/

function createNodeTables(value)   {
   createHierTable("#CurrentNode", value, ShowCurrent); //Shows the currently selected note from the treeview
   createHierTable("#HierNodes", value, ShowHierChildren); //Show the Children of the current node that are also parents. 
   
   createAttributeEditorTable("#ChildNodes", value, ShowChildren);  // show the leaf nodes in the attribute editor
   
   $("#ManageControls").show();   
}

/* --------------------------------------------------------
   
   Non-leaf Editor Table
   
------------------------------------------------------------*/

function createHierTable(tableDiv, value, children) {
   console.log(tableDiv);   
      
   var queryString = "&R1C1=" + value + "&R2C1=" + dimension +"&R3C1="+children;
   var grid = report.api.getCalculatedRange("treeview_data", "data", true, queryString);
      

	// get kendo hierarchical datasource
	var columnList = ["value", "label", "hasChildren", "isCalculated", "unaryOperator", "isLeaf", "sortOrder"];
	var fields = {
		
		label: {type: "string"},
		hasChildren: {type: "boolean"},
		isCalculated: {type: "boolean"},
		unaryOperator: {type: "string"},
		isLeaf: {type: "boolean"},
		sortOrder: {type: "number"},
      value: {type: "number"}
	};
   
   var gridDataSource = report.api.getKendoDataSource(grid, true, columnList, fields);   
   
   
      //"#ChildNodes"
      $(tableDiv).kendoGrid({
            dataSource : gridDataSource,
            //height: 500,
            //width: 600,
            sortable: true,
            filterable: true,
            selectable: "multiple cell",
            resizable: true,
            reorderable: true,               
            editable: true,               
            columns: [ {
                 field: "value",
                 width: 90,
                 title: "ID"            
            } ,  {                   
                 
                 field: "label",
                 title: "Member Name"            
             }]
         });   
   
   // if there's no data to display then hide then grid view.
   console.log(gridDataSource.view().length)
   if (gridDataSource.view().length > 0) {
      $(tableDiv).show();
      
      var q = $(tableDiv).data("kendoGrid");
      q.bind("save", fireHierUpdate);
      
   } else {
      $(tableDiv).hide();
   }
}


function fireHierUpdate(e){
   // This update is used by the parent and current member tables
   
   // Pass the update information to the DM Update Stored Proc. 
   console.log("GR");
   gr = e;
   var value = e.model.value;            
   
   // which row type  is being updated?
   if (e.model.isLeaf == true || e.model.isLeaf == "true") {
       isLeaf = "Leaf";
   } else {
       isLeaf = "Hier";        
   }
         
   
   for(var name in e.values){         
      
      
      console.log("save [" + value + "]: " + name + " = " + e.values[name] );
      
      
      spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMAttributeUpdate]',
          'parameters' : "@dimension='" + dimension + "', @tableType="+ isLeaf +", @node=" + value + " ,@AttributeColumn=" + name + " ,@newValue='" + e.values[name] + "'",
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
      };
      console.log(spdata);

      $.ajax({
          type: "POST",
          contentType: 'application/json; charset=utf-8',
          url: api.baseUrl + "ExecuteStoredProc/Execute",
          data: JSON.stringify(spdata)/* ,
          success: function(result) {
          }*/
      });   
   } 
   
   // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute.
   createNodeTables(selectedTreeNode);
   
}



/* --------------------------------------------------------
   
   Leaf Attribute Editor Table
   
------------------------------------------------------------*/


function createAttributeEditorTable(tableDiv, node, children) {
   
   
   // Dimension member list.
   var queryString = "&R1C1=" + node + "&R2C1=" + dimension +"&R3C1="+children;
   
   console.log(queryString);
   
   var grid = report.api.getCalculatedRange(schemaReport, rngAttributeData, true, queryString);         
   var headings = report.api.getCalculatedValues(schemaReport, rngAttributeHeading, true, queryString);
   
   // Provides information about the souce table data types and foreign keys. 
   var schema = report.api.getCalculatedRange(schemaReport, rngSchemaData, true, queryString);
   
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
      
   $(tableDiv).kendoGrid({         
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
      $(tableDiv).show();
      
      // Bind the Save event to the handler function.
      var q = $(tableDiv).data("kendoGrid");
      q.bind("save", fireAttributeUpdate);
      
   } else {
      $(tableDiv).hide();
   }
   
   
   
   
}


function foreginKeyData(FKtableName, FKColumn) {
   
   // report which provides the foreign key lookup
   var queryString = "&R1C1=" + FKtableName + "&R2C1=" + FKColumn;   
   var lgrid = report.api.getCalculatedRange(lookupReport, rngLookupData, true, queryString);               
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
      
      
      console.log("save [" + value + "]: " + name + " = " + e.values[name] );
            
      spdata = {
          'datasource': storedProcServer,
          'storedProcedure': '[dbo].[spDMAttributeUpdate]',
          'parameters' : "@dimension='" + dimension + "', @tableType=Leaf, @node=" + value + " ,@AttributeColumn=" + name + " ,@newValue='" + e.values[name] + "'",
          'resultStyleData' : "{'Style':'Prompt','PromptType':'Callout'}" 
      };
      console.log(spdata);
      
      
      $.ajax({
          type: "POST",
          contentType: 'application/json; charset=utf-8',
          url: api.baseUrl + "ExecuteStoredProc/Execute",
          data: JSON.stringify(spdata)/* ,
          success: function(result) {
          }*/
      });   
   }      
   
   // Recreate Tables after Update - in some instances a node can be listed in two tables - Current and Attribute.
   createNodeTables(selectedTreeNode);
}







// Examples of how to do things.
function example() {
   
var treeview = $("#treeview").data("kendoTreeView");

// find a node - only works when 
treeview.select(treeview.findByText("Trial Balance"));   
   
   
}































