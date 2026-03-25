package com.example.dgu_mobile

import com.google.android.material.datepicker.CalendarConstraints
import com.google.android.material.datepicker.MaterialDatePicker
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dgu_mobile/date_range")
            .setMethodCallHandler { call, result ->
                if (call.method != "pickDateRange") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any> ?: run {
                    result.error("bad_args", "Expected map", null)
                    return@setMethodCallHandler
                }
                val startMillis = (args["startMillis"] as Number).toLong()
                val endMillis = (args["endMillis"] as Number).toLong()
                val firstMillis = (args["firstMillis"] as Number).toLong()
                val lastMillis = (args["lastMillis"] as Number).toLong()

                val builder = MaterialDatePicker.Builder.dateRangePicker()
                builder.setSelection(androidx.core.util.Pair(startMillis, endMillis))
                builder.setCalendarConstraints(
                    CalendarConstraints.Builder()
                        .setStart(firstMillis)
                        .setEnd(lastMillis)
                        .build(),
                )
                val picker = builder.build()

                var completed = false
                fun complete(value: Map<String, Long>?) {
                    if (completed) return
                    completed = true
                    if (value == null) {
                        result.success(null)
                    } else {
                        result.success(value)
                    }
                }

                picker.addOnPositiveButtonClickListener { selection ->
                    if (selection != null) {
                        complete(
                            mapOf(
                                "startMillis" to selection.first,
                                "endMillis" to selection.second,
                            ),
                        )
                    } else {
                        complete(null)
                    }
                }
                // После OK сначала срабатывает positive, затем dismiss — не дублируем результат.
                picker.addOnDismissListener {
                    if (!completed) complete(null)
                }

                picker.show(supportFragmentManager, "MATERIAL_DATE_RANGE")
            }
    }
}
