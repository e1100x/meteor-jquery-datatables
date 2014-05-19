# # Base Mixin

# Include this mixin in your class like so :

###
  ```coffeescript
    class Whatever extends Component
      @extend DataTableMixins.Base
  ```
###

# Getter setter methods will be created for you instance properties if you add them to the data context in your constructor.

###
  ```coffeescript
    class Whatever extends Component
      @extend DataTableMixins.Base
      constructor: ( context = {} ) ->
        @data.instanceProperty = @instanceProperty
        super
  ```
###

DataTableMixins =
  Base:
    extended: ->
      if Meteor.isClient
        @include
          # ##### defaults
          defaults:
            # ###### Display Options
            jQueryUI: false
            autoWidth: true
            deferRender: false
            scrollCollapse: false
            paginationType: "full_numbers"
            # ##### Bootstrap 3 Markup
            # You can change this by setting `Template.dataTable.defaultOptions.sDom` property.
            # For some example Less / CSS styles check out [luma-ui's dataTable styles](https://github.com/LumaPictures/luma-ui/blob/master/components/dataTables/dataTables.import.less)
            dom: "<\"datatable-header\"fl><\"datatable-scroll\"rt><\"datatable-footer\"ip>"
            # ###### Language Options
            language:
              search: "_INPUT_"
              lengthMenu: "<span>Show :</span> _MENU_"
              # ##### Loading Message
              # Set `oLanguage.sProcessing` to whatever you want, event html. I haven't tried a Meteor template yet, could be fun!
              processing: "Loading"
              paginate:
                first: "First"
                last: "Last"
                next: ">"
                previous: "<"

          # #### `options` Object ( optional )
          # `options` are additional options you would like merged with the defaults `_.defaults options, defaultOptions`.
          # For more information on available dataTable options see the [DataTables Docs](https://datatables.net/usage/).
          # The default options are listed below and can be changed by setting `Template.dataTable.defaultOptions.yourDumbProperty`
          # ##### [DataTables Options Full Reference](https://datatables.net/ref)

          # ##### prepareOptions()
          prepareOptions: ->
            unless @options
              @data.options = {}
              @addGetterSetter "data", "options"
            @options().component = @
            unless @isDomSource()
              @options().data = if @rows then @rows() else []
              @options().columns = if @columns then @columns() else []
              # If the componet was declared with a collection and a query it is setup as a reactive datatable.
              if @collection and @query
                @log "xxx", @collection()
                @log "xxx", @query()
                @options().serverSide = true
                @options().processing = true
                # `options.sAjaxSource` is currently useless, but is passed into `fnServerData` by datatables.
                @options().ajaxSource = "useful?"
                # This binds the datatables `fnServerData` server callback to this component instance.
                # `_.debounce` is used to prevent unneccesary subcription calls while typing a search
                @options().serverData = _.debounce( @fnServerData.bind( @ ), 300 )
            @options _.defaults( @options(), @defaults )


          # ##### initializeDisplayLength()
          initializeDisplayLength: ->
            unless $.select2
              $( "#{ @selector() } .dataTables_length select" ).select2 minimumResultsForSearch: "-1"

          # ##### initializeFilterPlaceholder()
          initializeFilterPlaceholder: ->
            $("#{ @selector() } .dataTables_filter input[type=text]").attr "placeholder", "Type to filter..."

          # ##### prepareFooterFilter()
          initializeFooterFilter: ->
            if @selector() is 'datatable-add-row' and $.keyup
              self = @
              $( ".#{ @selector() } .dataTables_wrapper tfoot input" ).keyup ->
                target = @
                self.getDataTable().fnFilter target.value, $(".#{ self.getSelector() } .dataTables_wrapper tfoot input").index( target )

          # ##### isDomSource()
          # returns true if the dataTable is backed by a table in the dom
          isDomSource: ->
            if @dom then return @dom() else return false

          # ##### arrayToDictionary()
          arrayToDictionary: ( array, key ) ->
            dict = {}
            dict[obj[key]] = obj for obj in array when obj[ key ]?
            dict