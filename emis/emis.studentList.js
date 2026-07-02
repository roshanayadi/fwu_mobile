
$(function () {
    emis.CreateNamespace('studentList');

    (function (context) {
        context.Title = 'User Program Map';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForList(newValue, vm.LevelId());
                });

                vm.LevelId.subscribe(function (newValue) {
                    context.LoadProgramForList(vm.CollegeId(), newValue);
                });

                vm.searchStudents = function () {
                    context.SearchStudents();
                }

                return vm;
            }
        };

        context.Initialize = function (model, enableEdit) {
            enableEdit = true;
            context.ViewModel.StudentSearchModel = ko.mapping.fromJS(model, context.Mapping);
            ko.applyBindings(context.ViewModel.StudentSearchModel, $('#mainContent')[0]);
            var genderstore = {
                paginate: false,
                store: new DevExpress.data.CustomStore({
                    key: "Id",
                    loadMode: "raw",
                    load: function (loadOptions) {
                        var def = $.Deferred();
                        $.ajax({
                            url: '/lookup/getgenders',
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
                            url: '/lookup/getgenders',
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

            var batchStore = {
                paginate: false,
                store: new DevExpress.data.CustomStore({
                    key: "Id",
                    loadMode: "raw",
                    load: function (loadOptions) {
                        var def = $.Deferred();
                        $.ajax({
                            url: '/cascade/getbatch',
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
                            url: '/cascade/getbatch',
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

            var districtStore = {
                paginate: false,
                store: new DevExpress.data.CustomStore({
                    key: "Id",
                    loadMode: "raw",
                    load: function (loadOptions) {
                        var def = $.Deferred();
                        $.ajax({
                            url: '/lookup/getdistricts',
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
                            url: '/lookup/getdistricts',
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

            //var collegeStore = {
            //    paginate: false,
            //    store: new DevExpress.data.CustomStore({
            //        key: "Id",
            //        loadMode: "raw",
            //        load: function (loadOptions) {
            //            var def = $.Deferred();
            //            $.ajax({
            //                url: '/lookup/getcolleges',
            //                method: "Post",
            //                success: function (result) {
            //                    def.resolve(result.Data);
            //                }
            //            });
            //            return def.promise();
            //        },
            //        byKey: function (key) {
            //            var def = $.Deferred();
            //            $.ajax({
            //                url: '/lookup/getcolleges',
            //                method: "Post",
            //                data: { id: key },
            //                success: function (result) {
            //                    def.resolve(result.Data);
            //                }
            //            });
            //            return def.promise();
            //        }
            //    })
            //};


            $("#data-table").dxDataGrid({
                dataSource: [],
                showRowLines: true,
                columnAutoWidth: true,
                allowColumnReordering: true,
                allowColumnResizing: true,
                showBorders: true,
                showRowLines: true,
                editing: {
                    mode: 'popup',
                    allowUpdating: enableEdit,
                },
                columnChooser: {
                    enabled: true,
                    mode: "select"
                },
                stateStoring: {
                    enabled: true,
                    type: "localStorage",
                    storageKey: "studentlist.emis"
                },
                masterDetail: {
                    enabled: true,
                    template: function (c, o) {
                        var div = $("<div>").addClass("row").append(
                            $("<div />").addClass("col-md-2").html(` <div class="ibox-content">
                                    <img class="img-circle img-stu" src="/assets/img/avatar.png" height="190" width="190" />
                                    <div class="upload" data-context="Photo" data-instruction="Select Your Image"></div>
                                    <span class="helper">Max Size : 2 MB</span>
                                </div>`),
                            $("<div />").addClass("col-md-2").html(`<div class="ibox-content">
                                    <img class="img-circle sign-stu" src="/assets/img/signature.png" height="190" width="190" />
                                    <div class="signUpload" data-context="Photo" data-instruction="Select Your Signature"></div>
                                    <span class="helper">Max Size : 2 MB</span>
                                </div>`),
                        );
                        div.appendTo(c);
                        if (o.data.SignatureAttachmentId) {
                            ajaxRequest('/FileUpload/GetFile/' + o.data.SignatureAttachmentId, 'GET', null, function (response) {
                                if (response.IsSuccess) {
                                    $(".sign-stu", div).attr("src", "data:image/;base64," + response.Data);
                                }
                            });
                        }

                        if (o.data.PhotoAttachmentId) {
                            ajaxRequest('/FileUpload/GetFile/' + o.data.PhotoAttachmentId, 'GET', null, function (response) {
                                if (response.IsSuccess) {
                                    $(".img-stu", div).attr("src", "data:image/;base64," + response.Data);
                                }
                            });
                        }
                        let DynamicFileUploadAllowedTypes = ['image/png', 'image/jpeg', 'image/jpg'];
                        let maxSize = 2 * 1024 * 1024;

                        $(".upload", div).upload({
                            maxSize: maxSize,
                            beforeSend: function (formData, file) {
                                var isValid = DynamicFileUploadAllowedTypes.indexOf(file.file.type) >= 0// === 'image/png' || file.file.type === 'image/jpeg';
                                if (!isValid) {
                                    showMessage(context.Title, 'Invalid File Type. Only Png or JPEG is supported.', 'error');
                                    return false;
                                }
                                return formData; // cancel all jpgs
                            },
                            action: '/FileUpload/Upload/',
                            postKey: 'uploadFile',
                            label: 'Select Photo to update',
                            postData: {}
                        }).on("filecomplete.upload", function (e, file, response) {
                            var responseObj = JSON.parse(response || "{}");
                            if (responseObj.IsSuccess && responseObj.Data) {
                                ajaxRequest('/Student/Registration/updatephoto', 'POST', { data: { id: responseObj.Data.Id, studentRegistrationId: o.data.StudentRegistrationID } }, function (response) {
                                    if (response.IsSuccess) {
                                        $(".img-stu", div).attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                                        showMessage(context.Title, "Photo updated sucessfully.", 'success')
                                    }
                                    else {
                                        showMessage(context.Title, response.Message, 'error')
                                    }
                                });
                            }
                        })

                        $(".signUpload", div).upload({
                            maxSize: maxSize,
                            beforeSend: function (formData, file) {
                                var isValid = DynamicFileUploadAllowedTypes.indexOf(file.file.type) >= 0// === 'image/png' || file.file.type === 'image/jpeg';
                                if (!isValid) {
                                    showMessage(context.Title, 'Invalid File Type. Only Png or JPEG is supported.', 'error');
                                    return false;
                                }
                                return formData; // cancel all jpgs
                            },
                            action: '/FileUpload/Upload/',
                            postKey: 'uploadFile',
                            label: 'Select Sign to update',
                            postData: {}
                        }).on("filecomplete.upload", function (e, file, response) {
                            var responseObj = JSON.parse(response || "{}");
                            if (responseObj.IsSuccess && responseObj.Data) {
                                ajaxRequest('/Student/Registration/updatesign', 'POST', { data: { id: responseObj.Data.Id, studentRegistrationId: o.data.StudentRegistrationID } }, function (response) {
                                    if (response.IsSuccess) {
                                        $(".sign-stu", div).attr("src", "data:image/;base64," + responseObj.Data.FileContent);
                                        showMessage(context.Title, "Sign updated sucessfully.", 'success')
                                    }
                                    else {
                                        showMessage(context.Title, response.Message, 'error')
                                    }
                                });
                            }
                        })


                    }
                },
                columns: [
                    {
                        dataField: "BatchID",
                        caption: "Batch",
                        allowEditing: true,
                        validationRules: [{ type: 'required' }],
                        editorOptions: {
                            showClearButton: true,
                        },
                        lookup: {
                            dataSource: batchStore,
                            displayExpr: 'Description',
                            valueExpr: 'Id',
                        },
                    },
                    {
                        dataField: "RepeatBatchId",
                        caption: "Repeat Batch",
                        allowEditing: true,
                        editorOptions: {
                            showClearButton: true,
                        },
                        lookup: {
                            dataSource: batchStore,
                            displayExpr: 'Description',
                            valueExpr: 'Id',
                        },
                    },
                    {
                        dataField: "ProgramID",
                        caption: "Program",
                        validationRules: [{ type: 'required' }],
                        allowEditing: true,
                        lookup: {
                            dataSource(options) {
                                let data = (options ? options.data : {}) || {};
                                return {
                                    load: function (loadOptions) {
                                        var def = $.Deferred();
                                        $.ajax({
                                            url: '/lookup/getprograms',
                                            data: { CollegeId: data.CollegeID },
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
                                            url: '/lookup/getprograms',
                                            data: { CollegeId: data.CollegeID, id: key },
                                            method: "Post",
                                            data: { id: key },
                                            success: function (result) {
                                                def.resolve(result.Data);
                                            }
                                        });
                                        return def.promise();
                                    }
                                }
                            },
                            displayExpr: 'Description',
                            valueExpr: 'Id',
                        }
                    },
                    {
                        dataField: "CollegeID",
                        caption: "College",
                        allowEditing: true,
                        validationRules: [{ type: 'required' }],
                        lookup: {
                            dataSource(options) {
                                let data = (options ? options.data : {}) || {};
                                return {
                                    load: function (loadOptions) {
                                        var def = $.Deferred();
                                        $.ajax({
                                            url: '/lookup/getcolleges',
                                            data: { ProgramId: data.ProgramID },
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
                                            url: '/lookup/getcolleges',
                                            method: "Post",
                                            data: { ProgramId: data.ProgramID, id: key },
                                            success: function (result) {
                                                def.resolve(result.Data);
                                            }
                                        });
                                        return def.promise();
                                    }
                                }
                            },
                            displayExpr: 'Description',
                            valueExpr: 'Id',
                        }
                    },
                    //{
                    //    dataField: "CollegeRollNo",
                    //    validationRules: [{ type: 'required' }],
                    //},
                    {
                        dataField: "LevelName",
                        caption: "Level",
                        allowEditing: false
                    },
                    {
                        dataField: "RegistrationNo",
                        allowEditing: true
                    },
                    {
                        dataField: "FirstName",
                        allowEditing: true,
                        validationRules: [{ type: 'required' }],

                    },
                    {
                        dataField: "MiddleName",
                        allowEditing: true
                    },
                    {
                        dataField: "LastName",
                        allowEditing: true,
                        validationRules: [{ type: 'required' }],
                    },
                    {
                        dataField: "Email",
                    },
                    {
                        dataField: "ContactNo",
                    },
                    {
                        dataField: "BirthDateBS",
                        allowEditing: false
                    },
                    {
                        dataField: "GenderID",
                        caption: "Gender",
                        validationRules: [{ type: 'required' }],
                        lookup: {
                            dataSource: genderstore,
                            displayExpr: 'Description',
                            valueExpr: 'Id',
                        },


                    },
                    {
                        dataField: "DistrictID",
                        caption: "District",
                        lookup: {
                            dataSource: districtStore,
                            displayExpr: 'Description',
                            valueExpr: 'Id',
                        }
                    },
                    {
                        dataField: "IsActive",
                        allowEditing: true
                    }
                ],
                searchPanel: { visible: true },
                pager: {
                    allowedPageSizes: "auto",
                    displayMode: "adaptive",
                    infoText: "Page {0} of {1} ({2} items)",
                    showInfo: true,
                    showNavigationButtons: true,
                    showPageSizeSelector: true,
                    allowedPageSizes: [50, 100, 200, 500, 'all'],
                    visible: "auto"
                },
                paging: {
                    enabled: true,
                    pageIndex: 0,
                    pageSize: 50
                },
                export: {
                    enabled: true,
                    fileName: "Student List"
                }
            });
        }

        context.LoadProgramForList = function (newCollegeId, newLevelId) {
            if (newCollegeId && newLevelId && newCollegeId > 0 && newLevelId > 0) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: newLevelId } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.StudentSearchModel.Programs);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.StudentSearchModel.Programs);

            }
        };

        context.SearchStudents = function () {
            var gridDataSource = new DevExpress.data.DataSource({
                load: function () {
                    const d = $.Deferred();
                    var model = ko.mapping.toJS(context.ViewModel.StudentSearchModel);
                    $.ajax({
                        url: "/Student/Registration/SearchStudents",
                        method: "post",
                        data: model,
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
                        url: "/Student/Registration/UpdateStudent",
                        method: "post",
                        data: data,
                        success: function (result) {
                            if (result.IsSuccess)
                                d.resolve(result.Data);
                            else
                                d.reject("Error on updating data");
                        },
                        error: function () {
                            d.reject("Error on updating data");
                        }
                    });
                    return d.promise();
                },
            });

            $("#data-table").dxDataGrid("instance").option("dataSource", gridDataSource);
            //$("#data-table").dxDataGrid("instance").refresh();
        }

    })(emis.studentList);
});