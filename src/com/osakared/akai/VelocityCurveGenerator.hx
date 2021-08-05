package com.osakared.akai;

class VelocityCurveGenerator
{
    public static function generateVelocityCurve(velocityCurveType:VelocityCurveType, flatValue:Int):Array<Int>
    {
        return switch velocityCurveType {
            case Default: [for (i in 0...128) i];
            case Flat: [for (_ in 0...128) flatValue];
            case Exponential: generateExponentialVelocityCurve();
        }
    }

    public static function generateExponentialVelocityCurve():Array<Int>
    {
        var curve = new Array<Int>();
        for (i in 0...128) {
            var exp = Math.ceil(Math.pow(i/127.0, 2.0) * 127.0);
            curve.push(exp);
        }
        return curve;
    }
}