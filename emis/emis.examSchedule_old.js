$(function () {
    emis.CreateNamespace('examSchedule');

    (function (context) {

        context.Title = 'Exam Schedule';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    //
                    context.Search();
                }
                vm.ExamFormFeeRateSetup = function (data) {
                    context.ExamFormFeeRateSetup(data);
                }

                vm.ActivateExamSchedule = function (data, event) {
                    context.ActivateExamSchedule(data, event);
                }


                vm.EditClick = function (item) {
                    context.Edit(item.ExamScheduleID());
                }
                return vm;
            }
        };

        context.LoadProgram = function (levelId, ProgramPeriodTypeID, oldValue) {
            if (levelId > 0 && ProgramPeriodTypeID > 0) {
                ajaxRequest('/Lookup/GetProgramByPeriodTypeAndLevel', 'POST', { data: { levelId: levelId, ProgramPeriodTypeID: ProgramPeriodTypeID } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.AddNewModel.Programs);
                    $("#ProgramId").val(oldValue).trigger("chosen:updated");
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.AddNewModel.Programs);

            }
        };

        context.ActivateExamSchedule = function (data, event) {
            ajaxRequest('/Admin/ExamSchedule/ActivateExam', 'POST',
                {
                    data: { ExamScheduleId: data.ExamScheduleID() }
                }, function (response) {
                    if (response.IsSuccess) {
                        $(event.currentTarget).remove();
                        showMessage(context.Title, "Sucessfully activated exam schedule", 'success');
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ExamFormFeeRateSetup = function (data) {
            var feeName = {
                paginate: false,
                store: new DevExpress.data.CustomStore({
                    key: "Id",
                    loadMode: "raw",
                    requireTotalCount: false,
                    load: function (loadOptions) {
                        var def = $.Deferred();
                        $.ajax({
                            url: '/lookup/getfeename',
                            method: "Post",
                            success: function (result) {
                                def.resolve(result.Data);
                            }
                        });
                        return def.promise();
                    },
                    byKey: function (key) {
                        var def = $.Deferred();
                        $.ajax({
                            url: '/lookup/getfeename',
                            method: "Post",
                            data: { id: key },
                            success: function (result) {
                                def.resolve(result.Data);
                            }
                        });
                        return def.promise();
                    }
                })
            };
            var collegeType = {
                paginate: false,
                store: new DevExpress.data.CustomStore({
                    key: "Id",
                    requireTotalCount: false,
                    loadMode: "raw",
                    load: function (loadOptions) {
                        var def = $.Deferred();
                        $.ajax({
                            url: '/lookup/getcollegetype',
                            method: "Post",
                            success: function (result) {
                                def.resolve(result.Data);
                            }
                        });
                        return def.promise();
                    },
                    byKey: function (key) {
                        var def = $.Deferred();
                        $.ajax({
                            url: '/lookup/getcollegetype',
                            method: "Post",
                            data: { id: key },
                            success: function (result) {
                                def.resolve(result.Data);
                            }
                        });
                        return def.promise();
                    }
                })
            };

            var gridDataSource = new DevExpress.data.DataSource({
                load: function () {
                    const d = $.Deferred();
                    $.ajax({
                        url: "/admin/examschedule/getexamformfeerates",
                        method: "post",
                        data: { examscheduleId: data.ExamScheduleID() },
                        success: function (result) {
                            if (result.IsSuccess)
                                d.resolve(result.Data);
                            else
                                d.reject("Error on loading data");
                        },
                        error: function () {
                            d.reject("Error on loading data");
                        }
                    });
                    return d.promise();
                },

                update: function (key, values) {
                    const data = { ...key, ...values };
                    const d = $.Deferred();

                    $.ajax({
                        url: "/admin/examschedule/insertorupdateexamfeerate",
                        method: "post",
                        data: data,
                        success: function (result) {
                            if (result.IsSuccess)
                                d.resolve(result.Data);
                            else
                                d.reject(result.Message || "Error on updating data");
                        },
                        error: function () {
                            d.reject("Error on updating data");
                        }
                    });
                    return d.promise();
                },
                insert: function (data) {
                    const d = $.Deferred();

                    $.ajax({
                        url: "/admin/examschedule/insertorupdateexamfeerate",
                        method: "post",
                        data: data,
                        success: function (result) {
                            if (result.IsSuccess)
                                d.resolve(result.Data);
                            else
                                d.reject(result.Message || "Error on updating data");
                        },
                        error: function () {
                            d.reject("Error on updating data");
                        }
                    });
                    return d.promise();
                },
                remove: function (key) {
                    const d = $.Deferred();

                    $.ajax({
                        url: "/admin/examschedule/removeexamfee",
                        method: "post",
                        data: key,
                        success: function (result) {
                            if (result.IsSuccess)
                                d.resolve(result.Data);
                            else
                                d.reject("Error on deleting data");
                        },
                        error: function () {
                            d.reject("Error on deleting data");
                        }
                    });
                }
            });
            if ($("#popup").length == 0) {
                $('body').append($('<div id="popup" />'))
            }

            const popup = $('#popup').dxPopup({
                contentTemplate: function () {
                    return '<div class="fee-scroll"><div id="fee-rate"></div></div>';
                },
                onShowing: function (f) {
                    $('.fee-scroll').dxScrollView({
                        showScrollbar: 'always'
                    });

                    $('#fee-rate').dxDataGrid({
                        dataSource: gridDataSource,
                        editing: {
                            allowUpdating: true,
                            allowAdding: true,
                            allowDeleting: true,
                            mode: 'form', // 'batch' | 'cell' | 'form' | 'popup'
                            useIcons: false

                        },
                        onContentReady: function () {
                            let btn = $(".dx-datagrid-addrow-button")
                                .dxButton("instance");
                            btn.option("type", "default");
                            btn.option("stylingMode", "contained");
                            btn.option("template", function (e) { return '<span class="save-all">Add New Fee</span>' });
                        },
                        onRowPrepared: function (e) {
                            if (e.rowType == 'data' && e.data.IsActive) {
                                e.rowElement.addClass("bg-success");
                            }
                        },
                        onInitNewRow: function (e) {
                            e.data.ExamscheduleId = data.ExamScheduleID();
                        },
                        showRowLines: true,
                        showBorders: true,
                        columns: [
                            {
                                dataField: "ApplicableDate",
                                caption: "Start Date",
                                editorType: "dxDateBox",
                                editorOptions: {
                                    type: "datetime",
                                    dateSerializationFormat: "yyyy-MM-dd hh:mm:ss",
                                },
                                width: "auto",
                                validationRules: [{ type: 'required' }],
                                cellTemplate: function (c, o) {
                                    c.append(moment(o.value).format("YYYY-MM-DD hh:mm A"));
                                }
                            },
                            {
                                dataField: "ThroughDate",
                                caption: "End Date",
                                editorType: "dxDateBox",
                                editorOptions: {
                                    type: "datetime",
                                    dateSerializationFormat: "yyyy-MM-dd hh:mm:ss",
                                },
                                width: "auto",
                                validationRules: [{ type: 'required' }],
                                cellTemplate: function (c, o) {
                                    c.append(moment(o.value).format("YYYY-MM-DD hh:mm A"));
                                }
                            },
                            {
                                dataField: "ExamFormFeeNameId",
                                caption: "Fee Name",
                                lookup: {
                                    dataSource: feeName,
                                    displayExpr: 'Description',
                                    valueExpr: 'Id',
                                },
                                validationRules: [{ type: 'required' }],
                            },
                            {
                                dataField: "Amount",
                                dataType: "number",
                                validationRules: [{ type: 'required' }],

                            },
                            {
                                dataField: "CollegeTypeId",
                                lookup: {
                                    dataSource: collegeType,
                                    displayExpr: 'Description',
                                    valueExpr: 'Id',
                                },
                                caption: "College Type",
                                validationRules: [{ type: 'required' }],
                            },
                            {
                                dataField: "IsCollegeFee",
                                caption: "College Fee?",
                                dataType: "boolean",
                                editorType: "dxCheckBox",


                            },

                        ]
                    })
                },
                width: 900,
                height: 'auto',
                showTitle: true,
                title: 'Fee Rates',
                visible: true,
                dragEnabled: true,
                hideOnOutsideClick: false,
                showCloseButton: true,
                position: {
                    at: 'center',
                    my: 'center',
                    collision: 'fit',
                },
                toolbarItems: [{
                    locateInMenu: 'always',
                    widget: 'dxButton',
                    toolbar: 'top',
                    options: {
                        text: data.ExamScheduleName(),
                    },
                }, {
                    widget: 'dxButton',
                    toolbar: 'bottom',
                    location: 'after',
                    options: {
                        text: 'Close',
                        onClick() {
                            popup.hide();
                        },
                    },
                }],
            }).dxPopup('instance');
        }

        context.MappingCreate = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.Save = function () {
                    context.Save();
                }
                vm.LevelID.subscribe(function (newValue) {
                    context.LoadProgram(newValue, vm.ProgramPeriodTypeID());
                })

                vm.ProgramPeriodTypeID.subscribe(function (newValue) {
                    context.LoadProgram(vm.LevelID(), newValue);
                })

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            AcademicYearId: { required: true }
                        },
                        messages: {
                            AcademicYearId: { required: 'Academic Year is required' }
                        }
                    })
                }

                return vm;
            }
        };

        context.Search = function () {
            var model = ko.mapping.toJS(context.ViewModel);
            delete model.AcademicYears;
            ajaxRequest('/Admin/ExamSchedule/Index', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        window.data = response.Data;
                        var model = { Records: response.Data }
                        ko.mapping.fromJS(model, {}, context.ViewModel);
                    } else {
                        showMessage(context.Title, response.Message, 'error', function () {
                        });
                    }
                });

        }

        context.Edit = function (id) {
            window.location = '/Admin/ExamSchedule/Edit/' + id
        }

        context.Save = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AddNewModel);
            delete model.AcademicYears;
            delete model.Batches;
            delete model.ExamScheduleParents;
            delete model.ExamTypes;
            delete model.Levels;
            delete model.ProgramPeriodTypes;
            delete model.Programs;
            delete model.YearParts;
            ajaxRequest('/Admin/ExamSchedule/Create/', 'POST',
                {
                    data: { model: model },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        context.Initialize();
                        showMessage(context.Title, 'Exam Schedule saved successfully.', 'success', function () {
                            window.location = '/Admin/ExamSchedule/index'
                        });
                    }
                });
        }

        context.ApplyValidation = function () {
            $('#academicYearForm').validate({
                rules: {
                    AcademicYearName: {
                        required: true
                    },
                    AcademicYearCode: {
                        required: true
                    }
                },
                messages: {
                    AcademicYearName: {
                        required: 'Academi Year name is required.'
                    },
                    AcademicYearCode: {
                        required: 'Academic Year Code is required.'
                    }
                }
            });
        }

        context.Initialize = function (model) {

            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, context.Mapping, context.ViewModel);
            }
        }

        context.InitializeCreate = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.AddNewModel = ko.mapping.fromJS(model, context.MappingCreate);
                ko.applyBindings(context.ViewModel.AddNewModel, $('#mainContent')[0]);

                context.ViewModel.AddNewModel.ProgramPeriodTypeID.subscribe(function (newValue) {
                    context.LoadYearPartsForList(newValue);
                });

                context.LoadProgram(context.ViewModel.AddNewModel.LevelID(), context.ViewModel.AddNewModel.ProgramPeriodTypeID(), context.ViewModel.AddNewModel.ProgramId());

            } else {
                ko.mapping.fromJS(model, context.Mapping, context.ViewModel.AddNewModel);
            }
        }

        context.LoadYearPartsForList = function (newPeridTypeId) {
            if (newPeridTypeId > 0) {
                ajaxRequest('/Lookup/GetYearPartByProgramPeriod', 'POST', { data: { id: newPeridTypeId } }, function (response) {
                    var yearParts = [];
                    if (response.IsSuccess) {
                        yearParts = response.Data;
                    } else {
                        yearParts = [];
                    }
                    ko.mapping.fromJS(yearParts, {}, context.ViewModel.AddNewModel.YearParts);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.AddNewModel.YearParts);
            }
        }

    })(emis.examSchedule);
});