$(function () {
    emis.CreateNamespace('subjectDetail');

    (function (context) {

        context.Title = 'Subject Detail';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CurrentSubjectDetailVM = ko.mapping.fromJS(ko.toJS(vm.AddNewModel));

                vm.CurrentSubjectDetailVM.ProgramID.subscribe(function (newValue) {
                    if (newValue) {
                        ajaxRequest('/Subject/SubjectDetail/GetSubjectGroupByProgram/', 'GET', { data: { programId: newValue } }, function (response) {
                            if (response.IsSuccess) {
                                ko.mapping.fromJS(response.Data.SubjectGroups, {}, vm.SubjectGroups);
                                ko.mapping.fromJS(response.Data.YearParts, {}, vm.YearParts);
                            }
                            else {
                                showMessage(context.Title, response.Message, 'error');
                            }
                        })

                    }
                    else {
                        vm.CurrentSubjectDetailVM.SubjectGroups([]);
                        vm.CurrentSubjectDetailVM.YearParts([]);
                        //ko.mapping.fromJS([], {},  vm.CurrentSubjectDetailVM.SubjectGroups);
                    }
                });

                vm.AddNewClick = function () {
                    context.AddNew();
                }

                vm.EditClick = function (item) {
                    context.Edit(item.SubjectDetailID());
                }

                vm.SaveClick = function () {
                    context.Save();
                }

                return vm;
            }
        };

        context.Edit = function (id) {
            ajaxRequest('/Subject/SubjectDetail/Edit/', 'POST', { data: { id: id } }, function (response) {

                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.CurrentSubjectDetailVM);
                    $('#subjectDetailModal').modal('show');
                  

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.Save = function () {
            if (!$('#subjectDetailForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CurrentSubjectDetailVM);
            ajaxRequest('/Subject/SubjectDetail/Create', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'Subject Detail Saved successfully.', 'success', function () {
                            $('#subjectDetailModal').modal('hide');
                        });
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ApplyValidation = function () {
            $('#subjectDetailForm').validate({
                rules: {
                    ProgramID: {
                        required: true
                    },
                    YearPartID: {
                        required: true
                    },
                    SubjectCode: {
                        required: true,
                    },
                    SubjectName: {
                        required: true
                    },
                    TheoryFullMark: {
                        required: true
                    },
                    TheoryPassMark: {
                        required: true
                    },
                    SubjectTypeID: {
                        required: true
                    },
                    YearPartID: {
                        required: true
                    },
                    SubjectGroupID: {
                        required: true
                    },


                },
                messages: {
                    ProgramID: {
                        required: 'Program must be selected.'
                    },
                    YearPartID: {
                        required: 'Year Part must be selected.'
                    },
                    SubjectCode: {
                        required: 'Subject Code is required.',
                    },
                    SubjectName: {
                        required: 'Subject Name is required.'
                    },
                    TheoryFullMark: {
                        required: 'Theory Full Marks is required'
                    },
                    TheoryPassMark: {
                        required: 'Theory Pass Marks is required.'
                    }
                }
            });
        }

        context.AddNew = function () {
            ko.mapping.fromJS(ko.toJS(context.ViewModel.AddNewModel), {}, context.ViewModel.CurrentSubjectDetailVM);
            context.ApplyValidation();
            $('#subjectDetailModal').modal('show');
        }

        context.Initialize = function () {
            $("#subject-list").dxDataGrid({
                allowColumnReordering: true,
                allowColumnResizing: true,
                searchPanel: { visible: true },
                headerFilter: {
                    visible: true,
                },
                dataSource:[],
                export: {
                    enabled: true,
                    formats: "xlxs",
                    fileName:"Subjects"
                },
                toolbar: {
                    items: [
                        {
                            location: 'after',
                            widget: 'dxButton',
                            options: {
                                icon: 'plus',
                                type:"default",
                                text: "Add new",
                                onClick() {
                                    context.AddNew();
                                },
                            },
                        },
                        'columnChooserButton','searchPanel',
                    ],
                },
                paging: {
                    pageSize: 100
                },
                columns: [
                    {
                        dataField: "ProgramName",
                        groupIndex: 0,
                        showWhenGrouped:true
                    },
                    {
                        dataField: "YearPartName",
                        caption: "Year Part",
                        groupIndex: 1,
                        showWhenGrouped: true,

                    },
                    {
                        dataField: "SubjectName",
                    },
                    {
                        dataField: "SubjectGroupName",
                        caption: "Subject Group"
                    },
                    {
                        dataField: "SubjectCode",
                    },
                    {
                        dataField: "HasInternal",
                        caption: "Internal?"
                    },
                    {
                        dataField: "HasPractical",
                        caption: "Practical?"
                    },
                    {
                        cellTemplate: function (c, o) {
                            $('<a />').attr("href", "javascript:void(0)").addClass("btn btn-xs btn-primary").html(`<i class="fa fa-pencil"></i>&nbsp; Edit`).on("click", function () {
                                context.Edit(o.data.SubjectDetailID)
                            }).appendTo(c)
                        }
                    }

                ]
            });
            ajaxRequest('/Subject/SubjectDetail/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    $("#subject-list").dxDataGrid("instance").option("dataSource", response.Data.Records);
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);//subjectDetailModal
                        setTimeout(function () {
                            //$('.dataTables-subject').DataTable({
                            //    dom: '<"html5buttons"B>lTfgitp',
                            //    buttons: [
                            //        { extend: 'copy' },
                            //        { extend: 'csv' },
                            //        { extend: 'excel', title: 'SubjectFile' },
                            //        { extend: 'pdf', title: 'SubjectFile' },

                            //        {
                            //            extend: 'print',
                            //            customize: function (win) {
                            //                $(win.document.body).addClass('white-bg');
                            //                $(win.document.body).css('font-size', '10px');

                            //                $(win.document.body).find('table')
                            //                        .addClass('compact')
                            //                        .css('font-size', 'inherit');
                            //            }
                            //        }
                            //    ]

                            //});
                        }, 1000);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


    })(emis.subjectDetail);
});