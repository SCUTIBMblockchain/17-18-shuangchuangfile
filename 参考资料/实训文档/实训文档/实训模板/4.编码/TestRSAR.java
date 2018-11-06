package com.ibm.education;

import java.text.SimpleDateFormat;
import java.util.Date;

public class TestRSAR {

	/**
	 * This class is used to test RSAR java policy. It is a date and time format application.
	 */
	private static String defaultDatePattern = null;
	private static String defaultTimePattern = null;
	private static Date time = null;

	// ~ Methods
	// ================================================================

	/**
	 * output date and time string representing the date and time pattern
	 * @param args
	 */
	public static void main(String[] args) {
		System.out
				.println("This class is Date format application using to test RSAR Java policy");
		time = new Date();
		System.out.println(getDate(time));
		System.out.println(getDateTime(time));
	}

	/**
	 * Return default datePattern (MM/dd/yyyy)
	 * 
	 * @return a string representing the date pattern on the UI
	 */

	public static synchronized String getDatePattern() {
		defaultDatePattern = "MM/dd/yyyy";
		return defaultDatePattern;
	}

	/**
	 * Return default timePattern (HH:mm)
	 * 
	 * @return a string representing the time pattern on the UI
	 */
	public static String getTimePattern() {
		defaultTimePattern = "HH:mm";
		return defaultTimePattern;
	}

	/**
	 * This method attempts to return date in the form mm/dd/yyyy.
	 * 
	 * @param aDate
	 *            a date object
	 * @return a formatted string representation of the date
	 * 
	 * @see java.Util.date
	 */
	public static final String getDate(Date aDate) {
		SimpleDateFormat df = null;
		String returnValue = "";

		if (aDate != null) {
			df = new SimpleDateFormat(getDatePattern());
			returnValue = df.format(aDate);
		}

		return (returnValue);
	}

	/**
	 * This method generates a string representation of a date's time in the
	 * format you specify on input
	 * 
	 * @param aDate
	 *            a date object
	 * @return a formatted string representation of the time
	 * 
	 * @see java.text.SimpleDateFormat
	 */
	public static String getDateTime(Date aDate) {
		SimpleDateFormat df = null; String returnValue = "";

		if (aDate == null) {
			// System.out.println("aDate is null!");
		} else {
			df = new SimpleDateFormat(getTimePattern());
			returnValue = df.format(aDate);
		}

		return (returnValue);
	}
}
