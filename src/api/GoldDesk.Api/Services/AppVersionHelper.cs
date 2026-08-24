namespace GoldDesk.Api.Services;

public static class AppVersionHelper
{
    public static bool IsUpdateRequired(string? currentVersion, string latestVersion)
    {
        if (string.IsNullOrWhiteSpace(latestVersion))
            return false;

        if (string.IsNullOrWhiteSpace(currentVersion))
            return true;

        return CompareVersions(currentVersion, latestVersion) < 0;
    }

    public static int CompareVersions(string left, string right)
    {
        var leftParts = ParseVersionParts(left);
        var rightParts = ParseVersionParts(right);
        var length = Math.Max(leftParts.Length, rightParts.Length);

        for (var i = 0; i < length; i++)
        {
            var leftValue = i < leftParts.Length ? leftParts[i] : 0;
            var rightValue = i < rightParts.Length ? rightParts[i] : 0;
            if (leftValue != rightValue)
                return leftValue.CompareTo(rightValue);
        }

        return 0;
    }

    private static int[] ParseVersionParts(string version)
    {
        var normalized = version.Split('+', StringSplitOptions.TrimEntries)[0];
        return normalized
            .Split('.', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(part => int.TryParse(part, out var value) ? value : 0)
            .ToArray();
    }
}
