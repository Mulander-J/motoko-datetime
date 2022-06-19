import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Int "mo:base/Int";

//  Date and Time utilities for motoko
module{
    public type DateTime = {
        year: Int;
        month: Int;
        day: Int;
        hour: Int;
        minute: Int;
        second: Int;
        weekday: Int;
    };
    private type DateU = {
        #Y : (Int); 
        #YM : (Int, Int);
        #YMD : (Int, Int, Int);
        #YMDH : (Int, Int, Int, Int);
        #YMDHM : (Int, Int, Int, Int, Int);
    };

    private let ORIGIN_YEAR = 1970;

    private let SECONDS_NANO : Int = 1_000_000_000;

    private let MINUTE_IN_NANOSECS : Int = 60_000_000_000;
    private let HOUR_IN_NANOSECS : Int = 3600_000_000_000;
    private let DAY_IN_NANOSECS : Int = 86400_000_000_000;
    private let YEAR_IN_NANOSECS : Int = 31536000_000_000_000;
    private let LEAP_YEAR_IN_NANOSECS : Int = 31622400_000_000_000;

    public func isLeapYear(_year_ : Int) : Bool {
        if (_year_ % 4 != 0) {
            return false;
        };
        if (_year_ % 100 != 0) {
            return true;
        };
        if (_year_ % 400 != 0) {
            return false;
        };
        return true;
    };

    public func leapYearsBefore(_year_ : Int) : Int {
        let y = _year_ - 1;
        return  y / 4 - y / 100 + y / 400;
    };

    public func getDaysInMonth(_month_ : Int, _year_ : Int) : Int {
        switch(_month_){
            case (1 or 3 or 5 or 7 or 8 or 10 or 12){
                return 31;
            };
            case (4 or 6 or 9 or 11){
                return 30;
            };
            case (_){
                if(isLeapYear(_year_)){
                    return 29;
                };
                return 28;
            };
        };
    };
 
    public func parse(_time_ : Time.Time) : DateTime { 
        // Year
        let _year : Int = getYear(_time_);
        let buf : Int = leapYearsBefore(_year) - leapYearsBefore(ORIGIN_YEAR);
        var nanoSecsAccountedFor : Int = LEAP_YEAR_IN_NANOSECS * buf + YEAR_IN_NANOSECS * (_year - ORIGIN_YEAR - buf);
 
        // Month
        var nanosInMonth : Int = 1;
        var _month = 1;
        label findMonth for (_m in Iter.range(1, 12)) {
            nanosInMonth := DAY_IN_NANOSECS * getDaysInMonth(_m, _year);
            if (nanosInMonth + nanoSecsAccountedFor  > _time_) {
                _month := _m;
                break findMonth;  
            };
            nanoSecsAccountedFor  += nanosInMonth;
        };
 
        // Day
        var _day : Int = 1;
        label findDay for (_d in Iter.range(1, getDaysInMonth(_month, _year))) {        
            if (DAY_IN_NANOSECS + nanoSecsAccountedFor  > _time_) {
                _day := _d;
                break findDay;
            };
            nanoSecsAccountedFor  += DAY_IN_NANOSECS;
        };
 
        // Hour
        let _hour = getHour(_time_);
 
        // Minute
        let _minute = getMinute(_time_);
 
        // Second
        let _second = getSecond(_time_);
 
        // Day of week.
        let _weekday = getWeekday(_time_);

        return {
            year = _year;
            month = _month;
            day = _day;
            hour = _hour;
            minute = _minute;
            second = _second;
            weekday = _weekday;
        };
    };
 
    public func getYear(_time_ : Time.Time) : Int { 
        var y: Int = ORIGIN_YEAR + _time_ / YEAR_IN_NANOSECS;
        let numLeapYears: Int = leapYearsBefore(y) - leapYearsBefore(ORIGIN_YEAR);
        var nanoSecsAccountedFor : Int = LEAP_YEAR_IN_NANOSECS * numLeapYears
            + YEAR_IN_NANOSECS * (y - ORIGIN_YEAR - numLeapYears);
 
        while (nanoSecsAccountedFor  > _time_) {
            if (isLeapYear(y - 1)) {
                nanoSecsAccountedFor  -= LEAP_YEAR_IN_NANOSECS;
            } else {
                nanoSecsAccountedFor  -= YEAR_IN_NANOSECS;
            };
            y -= 1;
        };

        return y;
    };
 
    public func getMonth(_time_ : Time.Time) : Int {
        parse(_time_).month;
    };
 
    public func getDay(_time_ : Time.Time) : Int {
        parse(_time_).day;
    };
 
    public func getHour(_time_ : Time.Time) : Int {
        (_time_ / 60 / 60 / SECONDS_NANO) % 24;
    };
 
    public func getMinute(_time_ : Time.Time) : Int {
        (_time_ / 60 / SECONDS_NANO) % 60;
    };
 
    public func getSecond(_time_ : Time.Time) : Int {
        (_time_ / SECONDS_NANO)  % 60;
    };
 
    public func getWeekday(_time_ : Time.Time) : Int {
        (_time_ / DAY_IN_NANOSECS + 4) % 7;
    };
 

    public func toTime(_dateU_ : DateU) : Int {        
        switch _dateU_ {
            case (#Y y) {
                return _toTimestamp(y, 1, 1, 0, 0, 0);
            };
            case (#YM (y, m)) {
                return _toTimestamp(y, m, 1, 0, 0, 0);
            };
            case (#YMD (y, m, d)) {
                return _toTimestamp(y, m, d, 0, 0, 0);
            };
            case (#YMDH (y, m, d, h)) {
                return _toTimestamp(y, m, d, h, 0, 0);
            };
            case (#YMDHM (y, m, d, h, _m)) {
                return _toTimestamp(y, m, d, h, _m, 0);
            };
        };
    };
 
    private func _toTimestamp(_y_ : Int, _M_ : Int, _d_ : Int, _h_ : Int, _m_ : Int,  _s_ : Int) : Int {
        var timestamp : Int = 0;
        // Year
        for (y in Iter.range(ORIGIN_YEAR, _y_ - 1)) {
            if (isLeapYear(y)) {
                timestamp += LEAP_YEAR_IN_NANOSECS;
            } else {
                timestamp += YEAR_IN_NANOSECS;
            };
        };
 
        // Month
        var monthDayCounts : [var Int] = [var 31,28,31,30,31,30,31,31,30,31,30,31];        
        if (isLeapYear(_y_)) {
            monthDayCounts[1] := 29;
        } else {
            monthDayCounts[1] := 28;
        };
 
        for (m in Iter.range(1, _M_ - 1)) {
            timestamp += (DAY_IN_NANOSECS * monthDayCounts[m]);
        };
 
        // Day
        timestamp += (DAY_IN_NANOSECS * (_d_));
 
        // Hour
        timestamp += (HOUR_IN_NANOSECS * (_h_));
 
        // Minute
        timestamp += (MINUTE_IN_NANOSECS * (_m_));
 
        // Second
        timestamp += _s_;
 
        return timestamp;
    };
}
